{-# LANGUAGE TemplateHaskell #-}

module Types where

import Control.Lens (makeLenses)
import Data.Text (Text)

-- | Available image filters
data FilterType
    = None
    | Invert
    | Grayscale
    | Sepia
    | Brighten
    | Darken
    | Threshold
    | ChannelSwap
    | FlipHorizontal
    | Pixelate
    | BoxBlur
    deriving (Eq, Show, Enum, Bounded)

{- | THE BRAIN (Data Models & Events)

The AppModel holds the entire state of our application.
-}
data AppModel = AppModel
    { -- | Path to the original loaded image
      _originalImagePath :: Text,
      -- | Path to the temporary image shown in the UI
      _displayImagePath :: Text,
      -- | Path where the user wants to save the final image
      _saveImagePath :: Text,
      -- | The currently selected filter from the dropdown
      _selectedFilter :: FilterType,
      -- | Feedback for the user
      _statusMessage :: Text
    }
    deriving (Eq, Show)

makeLenses ''AppModel

-- | AppEvent represents everything that can happen in our app.
data AppEvent
    = AppInit
    | LoadImage Text
    | FilterSelected FilterType
    | FilterFinished Text
    | SaveImage Text
    | SaveFinished Text
    | ErrorOccurred Text
    deriving (Eq, Show)
