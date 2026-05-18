{-# LANGUAGE OverloadedStrings #-}
module UI (buildUI, handleEvent) where

import Monomer
import Types
import Filter
import Control.Lens
import Data.Text (pack, unpack)

-- | THE FACE (User Interface & Layout)

buildUI :: WidgetEnv AppModel AppEvent -> AppModel -> WidgetNode AppModel AppEvent
buildUI wenv model = vstack [
    -- Header Title
    label "Haskell Image Filter" `styleBasic` [textFont "Medium", textSize 24, paddingB 10],

    -- Top Controls (Load & Filter)
    hstack [
      label "Load Image: ",
      spacer,
      textField originalImagePath `styleBasic` [width 200],
      spacer,
      button "Load" (LoadImage (model ^. originalImagePath)),
      
      spacer_ [width 30], -- Larger gap
      
      label "Filter: ",
      spacer,
      textDropdown_ selectedFilter [minBound .. maxBound] (pack . show) [onChange FilterSelected] `styleBasic` [width 150]
    ] `styleBasic` [paddingB 15],

    -- Dynamic Image Display Box
    box_ [alignCenter, alignMiddle] (image_ (model ^. displayImagePath) [fitEither]) 
      `styleBasic` [
        sizeReqW (expandSize 100 1), 
        sizeReqH (expandSize 100 1), 
        border 1 (rgbHex "#555555"), 
        padding 10,
        bgColor (rgbHex "#1E1E1E")
      ],

    spacer,

    -- Bottom Controls (Save)
    hstack [
      label "Save As: ",
      spacer,
      textField saveImagePath `styleBasic` [width 200],
      spacer,
      button "Save Image" (SaveImage (model ^. saveImagePath))
    ] `styleBasic` [paddingT 15, paddingB 15],

    -- Status/Error Message
    label (model ^. statusMessage) `styleBasic` [textColor (rgbHex "#FF5555")]
    
  ] `styleBasic` [padding 20]


-- | THE TRAFFIC CONTROLLER

handleEvent :: WidgetEnv AppModel AppEvent -> WidgetNode AppModel AppEvent -> AppModel -> AppEvent -> [AppEventResponse AppModel AppEvent]
handleEvent wenv node model evt = case evt of
  AppInit -> []
  
  LoadImage path ->
    -- When loading a new image, reset the display path to the new image, reset the filter to None.
    [Model (model & originalImagePath .~ path 
                  & displayImagePath .~ path 
                  & selectedFilter .~ None
                  & statusMessage .~ "Loaded image: " <> path)]
  
  FilterSelected fType ->
    let inPath = model ^. originalImagePath
        tempPath = "assets/temp_display_" ++ show fType ++ ".png"
        task = do
          if fType == None
            then return (FilterFinished inPath) -- If None, just show original
            else do
              res <- applyFilter fType (unpack inPath) tempPath
              case res of
                Left err -> return (ErrorOccurred (pack err))
                Right _ -> return (FilterFinished (pack tempPath))
    in [ Model (model & selectedFilter .~ fType & statusMessage .~ "Applying filter...")
       , Task task ]
  
  FilterFinished outPath ->
    [Model (model & displayImagePath .~ outPath & statusMessage .~ "Filter applied successfully!")]
  
  SaveImage path ->
    let currentDisplay = model ^. displayImagePath
        task = do
          res <- copyImage (unpack currentDisplay) (unpack path)
          case res of
            Left err -> return (ErrorOccurred (pack err))
            Right _ -> return (SaveFinished path)
    in [ Task task ]

  SaveFinished path ->
    [Model (model & statusMessage .~ "Image saved to: " <> path)]

  ErrorOccurred err ->
    [Model (model & statusMessage .~ ("Error: " <> err))]
