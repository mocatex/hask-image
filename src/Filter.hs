module Filter (applyFilter, copyImage) where

import Codec.Picture
import Codec.Picture.Types (pixelMap)
import Types (FilterType(..))
import System.Directory (copyFile)
import Control.Exception (try, SomeException)

-- | THE LAB (Pure Image Processing)
-- 
-- This file contains ONLY pure functional logic for modifying images.

--------------------------------------------------------------------------------
-- 1. Pure Pixel Transformations
--------------------------------------------------------------------------------

invertPixel :: PixelRGB8 -> PixelRGB8
invertPixel (PixelRGB8 r g b) = PixelRGB8 (255 - r) (255 - g) (255 - b)

grayscalePixel :: PixelRGB8 -> PixelRGB8
grayscalePixel (PixelRGB8 r g b) =
  let v = round (0.299 * fromIntegral r + 0.587 * fromIntegral g + 0.114 * fromIntegral b)
  in PixelRGB8 v v v

-- | Selects the pure function based on the requested filter type.
getFilterFunc :: FilterType -> (PixelRGB8 -> PixelRGB8)
getFilterFunc Invert = invertPixel
getFilterFunc Grayscale = grayscalePixel
getFilterFunc None = id

--------------------------------------------------------------------------------
-- 2. I/O Operations
--------------------------------------------------------------------------------

-- | Loads an image, applies the requested filter, and saves it to an output path.
applyFilter :: FilterType -> FilePath -> FilePath -> IO (Either String ())
applyFilter filterType inputPath outputPath = do
  dynImage <- readImage inputPath
  case dynImage of
    Left err -> return (Left err)
    Right img -> do
      let rgbImage = convertRGB8 img
          -- Apply the corresponding pure function
          filtered = pixelMap (getFilterFunc filterType) rgbImage
      savePngImage outputPath (ImageRGB8 filtered)
      return (Right ())

-- | Simply copies a file (used for saving or resetting to None).
copyImage :: FilePath -> FilePath -> IO (Either String ())
copyImage src dest = do
  result <- try (copyFile src dest) :: IO (Either SomeException ())
  case result of
    Left err -> return $ Left (show err)
    Right _  -> return $ Right ()
