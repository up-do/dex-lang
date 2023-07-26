let TYPES = ./../../../updo/types.dhall

let null = https://prelude.dhall-lang.org/List/null

in  \(pkgs-done : List Text) ->
    \(stackage-resolver : Text) ->
      let pkgs-todo = ../../pkgs-upgrade-todo.dhall

      let pkg-config =
            { constraints = ./../constraints.dhall
            , source-pkgs =
              { deps-external = ./../deps-external.dhall
              , deps-internal = ./../deps-internal.dhall
              , forks-external = ./../forks-external.dhall
              , forks-internal = ./../forks-internal.dhall
              }
            }

      in  ''
          ${../../../updo/text-templates/dhall2cabal.dhall
              stackage-resolver
              ( if    null Text pkgs-todo
                then  TYPES.PkgSet.AllPkgs pkgs-done
                else  TYPES.PkgSet.PkgUpgrade
                        { todo = pkgs-todo, done = pkgs-done }
              )
              pkg-config}
          ${./cabal-snippet.dhall}
          ''
