# Versions of GHC and stackage resolver, the ones we're on and the next ones
# we're upgrading to.
GHC_VERSION ?= 8.10.7
STACKAGE_VERSION ?= lts-18.23

# For the upgrade, pick a matching pair of ghc-version and stack resolver.
GHC_UPGRADE ?= 8.10.7
STACKAGE_UPGRADE ?= lts-18.23

# Imports can be relative to the project or relative to importing file.
# ImportRelative works with cabal-3.10 and is the default.
# ProjectRelative works with cabal-3.8.
CABAL_RELATIVITY ?= ImportRelative