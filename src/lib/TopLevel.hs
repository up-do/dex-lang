-- Copyright 2019 Google LLC
--
-- Use of this source code is governed by a BSD-style
-- license that can be found in the LICENSE file or at
-- https://developers.google.com/open-source/licenses/bsd

{-# LANGUAGE FlexibleContexts #-}

module TopLevel (evalBlock, Backend (..)) where

import Control.Exception hiding (throw)
import Control.Monad.Writer.Strict  hiding (pass)
import Control.Monad.Except hiding (Except)
import Data.Text.Prettyprint.Doc

import Syntax
import DeShadow
import Env
import Type
import Inference
import Normalize
import Simplify
import Serialize
import Imp
import JIT
import PPrint
import Util (highlightRegion)

data Backend = Jit | Interp
type TopPassM a = ExceptT Err (WriterT [Output] IO) a
type Pass a b = a -> TopPassM b

-- TODO: handle errors due to upstream modules failing
evalBlock :: Backend -> TopEnv -> SourceBlock -> IO (TopEnv, Result)
evalBlock _ env block = do
  (ans, outs) <- runTopPassM $ addErrSrc block $ evalSourceBlock env (sbContents block)
  case ans of
    Left err   -> return (mempty, Result outs (Left err))
    Right env' -> return (env'  , Result outs (Right ()))

runTopPassM :: TopPassM a -> IO (Except a, [Output])
runTopPassM m = runWriterT $ runExceptT m

evalSourceBlock :: TopEnv -> SourceBlock' -> TopPassM TopEnv
evalSourceBlock env block = case block of
  RunModule m -> filterOutputs (const False) $ evalModule env m
  Command cmd (v, m) -> case cmd of
    EvalExpr fmt -> do
      env' <- filterOutputs (const False) $ evalModule env m
      let (L val) = env' ! v
      val' <- liftIO $ loadAtomVal val
      tell [ValOut fmt val']
      return mempty
    GetType -> do  -- TODO: don't actually evaluate it
      env' <- filterOutputs (const False) $ evalModule env m
      let (L val) = env' ! v
      val' <- liftIO $ loadAtomVal val
      tell [TextOut $ pprint (getType val')]
      return mempty
    ShowPasses -> liftM (const mempty) $ filterOutputs f $ evalModule env m
      where f out = case out of PassInfo _ _ -> True; _ -> False
    ShowPass s -> liftM (const mempty) $ filterOutputs f $ evalModule env m
      where f out = case out of PassInfo s' _ | s == s' -> True; _ -> False
    _ -> return mempty -- TODO
  IncludeSourceFile _ -> undefined
  LoadData _ _ _      -> undefined
  UnParseable _ s -> throw ParseErr s
  _               -> return mempty

-- TODO: extract only the relevant part of the env we can check for module-level
-- unbound vars and upstream errors here. This should catch all unbound variable
-- errors, but there could still be internal shadowing errors.
evalModule :: TopEnv -> Pass FModule TopEnv
evalModule env = inferTypes env >=> evalTyped env

-- TODO: check here for upstream errors
inferTypes :: TopEnv -> Pass FModule Module
inferTypes env m = ($ m) $
      namedPass "deshadow"       (liftEither . deShadowModule env) (const (return ()))
  >=> namedPass "type inference" (liftEither . inferModule    env) checkFModule
  >=> namedPass "normalize"      (return     . normalizeModule   ) checkModule

evalTyped :: TopEnv -> Pass Module TopEnv
evalTyped env m = ($ m) $
      namedPass "simplify" (return . simplifyPass env) checkModule
  >=> namedPass "imp"      (return . toImpModule)      checkImpModule
  >=> namedPass "jit"      (liftIO . evalModuleJIT)    (const (return ()))

namedPass :: (Pretty a, Pretty b)
          => String -> Pass a b -> (b -> Except ()) -> Pass a b
namedPass name pass check x = do
  (ans, s) <- withDebugCtx passCtx $ printedPass (pass x)
  tell [PassInfo name s]
  withDebugCtx checkCtx $ liftEither $ check ans
  return ans
  where
    passCtx  = name ++ " pass with input:\n" ++ pprint x
    checkCtx = "Checking post-" ++ name ++ ":\n" ++ pprint x

printedPass :: Pretty a => TopPassM a -> TopPassM (a, String)
printedPass m = do
  ans <- m
  let s = pprint ans
  -- uncover exceptions by forcing evaluation of printed result
  _ <- liftIO $ evaluate (length s)
  return (ans, s)

filterOutputs :: (Output -> Bool) -> TopPassM a -> TopPassM a
filterOutputs f m = do
  (ans, outs) <- liftIO $ runTopPassM m
  tell $ filter f outs
  liftEither ans

asTopPassM :: IO (Except a, [Output]) -> TopPassM a
asTopPassM m = do
  (ans, outs) <- liftIO m
  tell outs
  liftEither ans

withDebugCtx :: String -> TopPassM a -> TopPassM a
withDebugCtx msg m = catchError (catchHardErrors m) $ \e -> throwError (addDebugCtx msg e)

addErrSrc :: MonadError Err m => SourceBlock -> m a -> m a
addErrSrc block m = m `catchError` (throwError . addCtx block)

addCtx :: SourceBlock -> Err -> Err
addCtx block err@(Err e src s) = case src of
  Nothing -> err
  Just (start, stop) ->
    Err e Nothing $ s ++ "\n\n" ++ ctx
    where n = sbOffset block
          ctx = highlightRegion (start - n, stop - n) (sbText block)

addDebugCtx :: String -> Err -> Err
addDebugCtx ctx (Err CompilerErr c msg) = Err CompilerErr c msg'
  where msg' = msg ++ "\n=== context ===\n" ++ ctx ++ "\n"
addDebugCtx _ e = e

catchHardErrors :: TopPassM a -> TopPassM a
catchHardErrors m = asTopPassM $ runTopPassM m `catch` asCompilerErr
  where asCompilerErr :: SomeException -> IO (Except a, [Output])
        asCompilerErr e = return (Left $ Err CompilerErr Nothing (show e), [])
