\(stackage-resolver : Optional Text) ->
  let resolver =
        merge
          { None = ""
          , Some =
              \(r : Text) ->
                ''

                resolver: ${r}''
          }
          stackage-resolver

  in  ''
      # Copyright 2020 Google LLC
      #
      # Use of this source code is governed by a BSD-style
      # license that can be found in the LICENSE file or at
      # https://developers.google.com/open-source/licenses/bsd

      user-message: "WARNING: This stack project is generated."

      nix:
        enable: false
        packages: [ libpng llvm_12 pkg-config zlib ]

      ghc-options:
        containers: -fno-prof-auto -O2
        hashable: -fno-prof-auto -O2
        llvm-hs-pure: -fno-prof-auto -O2
        llvm-hs: -fno-prof-auto -O2
        megaparsec: -fno-prof-auto -O2
        parser-combinators: -fno-prof-auto -O2
        prettyprinter: -fno-prof-auto -O2
        store-core: -fno-prof-auto -O2
        store: -fno-prof-auto -O2
        unordered-containers: -fno-prof-auto -O2
      ${resolver}''
