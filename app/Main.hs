{-# LANGUAGE OverloadedStrings #-}
module Main where

import Monomer
import Types
import UI

-- | THE ENGINE ROOM (Entry Point)

main :: IO ()
main = do
  startApp model handleEvent buildUI config
  where
    config = [
      appWindowTitle "Haskell Image Filter",
      appTheme darkTheme,
      appFontDef "Regular" "./assets/fonts/Roboto-Regular.ttf",
      appFontDef "Medium" "./assets/fonts/Roboto-Medium.ttf",
      appInitEvent AppInit
      ]
    
    model = AppModel {
      _originalImagePath = "assets/sample.jpg",
      _displayImagePath = "assets/sample.jpg",
      _saveImagePath = "output.png",
      _selectedFilter = None,
      _statusMessage = "Welcome! Load an image and select a filter."
    }
