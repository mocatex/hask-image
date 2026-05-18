{-# LANGUAGE TemplateHaskell #-}
module Types where

import Control.Lens (makeLenses)
import Data.Text (Text)

-- | Available image filters
data FilterType 
  = None 
  | Invert 
  | Grayscale 
  deriving (Eq, Show, Enum, Bounded)

-- | THE BRAIN (Data Models & Events)
-- 
-- The AppModel holds the entire state of our application.
data AppModel = AppModel
  { _originalImagePath :: Text       -- ^ Path to the original loaded image
  , _displayImagePath  :: Text       -- ^ Path to the temporary image shown in the UI
  , _saveImagePath     :: Text       -- ^ Path where the user wants to save the final image
  , _selectedFilter    :: FilterType -- ^ The currently selected filter from the dropdown
  , _statusMessage     :: Text       -- ^ Feedback for the user
  } deriving (Eq, Show)

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
