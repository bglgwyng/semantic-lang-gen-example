{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Main (main) where

import AST.Unmarshal
import Language.Go.AST
import TreeSitter.Go

main :: IO ()
main = do
  let source = "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"Hello, World!\")\n}"

  typedAst <- parseByteString @SourceFile @() tree_sitter_go source
  print typedAst
