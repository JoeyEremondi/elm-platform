{-| This script builds any version of the Elm Platform from source.
Before you use it, make sure you have the Haskell Platform with a recent
version of cabal.

To install a released version of Elm, run something like this:

    runhaskell BuildFromSource.hs 0.15

Whatever directory you run this in, you will now have a new directory for the
Elm Platform, like this:

    Elm-Platform/0.15/
        bin/             -- all the relevant executables
        elm-make/        -- git repo for the build tool, ready to edit
        elm-repl/        -- git repo for the REPL, ready to edit
        ...

All of the executables you need are in bin/ so add
wherever/Elm-Platform/0.15/bin to your PATH to use them from anywhere.

You can build many versions of the Elm Platform, so it is possible to have
Elm-Platform/0.15/ and Elm-Platform/0.12.3/ with no problems. It is up to you
to manage your PATH variable or symlinks though.

To get set up with the master branch of all Elm Platform projects, run this:

    runhaskell BuildFromSource.hs master

From there you can start developing on any of the projects, switching branches
and testing interactions between projects.
-}
module Main where

import qualified Data.List as List
import qualified Data.Map as Map
import System.Directory (createDirectoryIfMissing, setCurrentDirectory, getCurrentDirectory)
import System.Environment (getArgs)
import System.Exit (ExitCode, exitFailure)
import System.FilePath ((</>))
import System.IO (hPutStrLn, stderr)
import System.Process (rawSystem)


(=:) = (,)

-- NOTE: The order of the dependencies is also the build order,
-- so do not just go alphebetizing things.
configs :: Map.Map String [(String, (String, String))]
configs =
  Map.fromList
    [
      "master" =:
        [ "elm-compiler" =: ("elm-lang", "master")
        , "elm-package"  =: ("elm-lang", "master")
        , "elm-make"     =: ("elm-lang", "master")
        , "elm-reactor"  =: ("elm-lang", "master")
        , "elm-repl"     =: ("elm-lang", "master")
        ]
    ,
      "tco" =:
        [ "elm-compiler" =: ("JoeyEremondi", "master")
        , "elm-package"  =: ("elm-lang", "master")
        , "elm-make"     =: ("JoeyEremondi", "master")
        , "elm-reactor"  =: ("elm-lang", "master")
        , "elm-repl"     =: ("elm-lang", "master")
        ]
    ,      
      "0.15.1" =:
        [ "elm-compiler" =: ("elm-lang", "0.15.1")
        , "elm-package"  =: ("elm-lang", "0.5.1")
        , "elm-make"     =: ("elm-lang", "0.2")
        , "elm-reactor"  =: ("elm-lang", "0.3.2")
        , "elm-repl"     =: ("elm-lang", "0.4.2")
        ]
    ,
      "0.15" =:
        [ "elm-compiler" =: ("elm-lang", "0.15")
        , "elm-package"  =: ("elm-lang", "0.5")
        , "elm-make"     =: ("elm-lang", "0.1.2")
        , "elm-reactor"  =: ("elm-lang", "0.3.1")
        , "elm-repl"     =: ("elm-lang", "0.4.1")
        ]
    ,
      "0.14.1" =:
        [ "elm-compiler" =: ("elm-lang", "0.14.1")
        , "elm-package"  =: ("elm-lang", "0.4")
        , "elm-make"     =: ("elm-lang", "0.1.1")
        , "elm-reactor"  =: ("elm-lang", "0.3")
        , "elm-repl"     =: ("elm-lang", "0.4")
        ]
    ,
      "0.14" =:
        [ "elm-compiler" =: ("elm-lang", "0.14")
        , "elm-package"  =: ("elm-lang", "0.2")
        , "elm-make"     =: ("elm-lang", "0.1")
        , "elm-reactor"  =: ("elm-lang", "0.2")
        , "elm-repl"     =: ("elm-lang", "0.4")
        ]
    ,
      "0.13" =:
        [ "Elm"         =: ("elm-lang", "0.13")
        , "elm-reactor" =: ("elm-lang", "0.1")
        , "elm-repl"    =: ("elm-lang", "0.3")
        , "elm-get"     =: ("elm-lang", "0.1.3")
        ]
    ,
      "0.12.3" =:
        [ "Elm"        =: ("elm-lang", "0.12.3")
        , "elm-server" =: ("elm-lang", "0.11.0.1")
        , "elm-repl"   =: ("elm-lang", "0.2.2.1")
        , "elm-get"    =: ("elm-lang", "0.1.2")
        ]
    ]


main :: IO ()
main =
 do args <- getArgs
    case args of
      [version] | Map.member version configs ->
          let artifactDirectory = "Elm-Platform" </> version
              repos = configs Map.! version
          in
              makeRepos artifactDirectory repos

      _ ->
        do hPutStrLn stderr $
               "Expecting one of the following values as an argument:\n" ++
               "    " ++ List.intercalate ", " (Map.keys configs)
           exitFailure


makeRepos :: FilePath -> [(String, (String, String))] -> IO ()
makeRepos artifactDirectory repos =
 do createDirectoryIfMissing True artifactDirectory
    setCurrentDirectory artifactDirectory
    root <- getCurrentDirectory
    cabal [ "sandbox", "init" ]
    mapM_ (uncurry (makeRepo root)) repos


makeRepo :: FilePath -> String -> (String, String) -> IO ()
makeRepo root projectName (userName, version) =
 do  -- get the right version of the repo
    git [ "clone", "https://github.com/" ++ userName ++ "/" ++ projectName ++ ".git" ]
    setCurrentDirectory projectName
    git [ "checkout", version ]
    git [ "pull" ]

    -- actually build things
    cabal [ "sandbox", "init", "--sandbox=" ++ root ]
    cabal [ "install", "-j", "--enable-library-profiling", "--enable-executable-profiling" ]

    -- move back into the root
    setCurrentDirectory root


-- HELPER FUNCTIONS

cabal :: [String] -> IO ExitCode
cabal = rawSystem "cabal"

git :: [String] -> IO ExitCode
git = rawSystem "git"
