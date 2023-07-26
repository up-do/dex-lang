\(stackage-resolver : Text) ->
\(ghc-version : Text) ->
  let project-dhall2config = ../../../updo/text-templates/dhall2config.dhall

  in  ''
      ${./cabal-snippet.dhall}
      ${project-dhall2config stackage-resolver ghc-version}
      ''
