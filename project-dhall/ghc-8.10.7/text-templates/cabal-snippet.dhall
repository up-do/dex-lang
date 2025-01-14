''
-- Copyright 2020 Google LLC
--
-- Use of this source code is governed by a BSD-style
-- license that can be found in the LICENSE file or at
-- https://developers.google.com/open-source/licenses/bsd

program-options
  ghc-options: -fhide-source-paths

package containers { ghc-options: -fno-prof-auto -O2 }
package hashable { ghc-options: -fno-prof-auto -O2 }
package llvm-hs-pure { ghc-options: -fno-prof-auto -O2 }
package llvm-hs { ghc-options: -fno-prof-auto -O2 }
package megaparsec { ghc-options: -fno-prof-auto -O2 }
package parser-combinators { ghc-options: -fno-prof-auto -O2 }
package prettyprinter { ghc-options: -fno-prof-auto -O2 }
package store-core { ghc-options: -fno-prof-auto -O2 }
package store { ghc-options: -fno-prof-auto -O2 }
package unordered-containers { ghc-options: -fno-prof-auto -O2 }''
