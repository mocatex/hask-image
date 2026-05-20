module Filter (applyFilter, copyImage) where

import Codec.Picture
import Codec.Picture.Types (pixelMap)
import Control.Exception (SomeException, try)
import System.Directory (copyFile)
import Types (FilterType (..))

{- | THE LAB (Pure Image Processing)

This file contains ONLY pure functional logic for modifying images.
-}

--------------------------------------------------------------------------------
-- 1. Pure Pixel Transformations
--------------------------------------------------------------------------------

invertPixel :: PixelRGB8 -> PixelRGB8
invertPixel (PixelRGB8 r g b) = PixelRGB8 (255 - r) (255 - g) (255 - b)

grayscalePixel :: PixelRGB8 -> PixelRGB8
grayscalePixel (PixelRGB8 r g b) =
    let v = round (0.299 * fromIntegral r + 0.587 * fromIntegral g + 0.114 * fromIntegral b)
     in PixelRGB8 v v v

clamp8 :: Int -> Pixel8
clamp8 x = fromIntegral (max 0 (min 255 x))

sepiaPixel :: PixelRGB8 -> PixelRGB8
sepiaPixel (PixelRGB8 r g b) =
    let rf = fromIntegral r :: Double
        gf = fromIntegral g :: Double
        bf = fromIntegral b :: Double
        nr = round (0.393 * rf + 0.769 * gf + 0.189 * bf)
        ng = round (0.349 * rf + 0.686 * gf + 0.168 * bf)
        nb = round (0.272 * rf + 0.534 * gf + 0.131 * bf)
     in PixelRGB8 (clamp8 nr) (clamp8 ng) (clamp8 nb)

brightenPixel :: PixelRGB8 -> PixelRGB8
brightenPixel (PixelRGB8 r g b) =
    PixelRGB8 (clamp8 (fromIntegral r + 40)) (clamp8 (fromIntegral g + 40)) (clamp8 (fromIntegral b + 40))

darkenPixel :: PixelRGB8 -> PixelRGB8
darkenPixel (PixelRGB8 r g b) =
    PixelRGB8 (clamp8 (fromIntegral r - 40)) (clamp8 (fromIntegral g - 40)) (clamp8 (fromIntegral b - 40))

thresholdPixel :: PixelRGB8 -> PixelRGB8
thresholdPixel (PixelRGB8 r g b) =
    let v = round (0.299 * fromIntegral r + 0.587 * fromIntegral g + 0.114 * fromIntegral b) :: Int
        o = if v >= 128 then 255 else 0
     in PixelRGB8 o o o

channelSwapPixel :: PixelRGB8 -> PixelRGB8
channelSwapPixel (PixelRGB8 r g b) = PixelRGB8 b r g

{- | Flips the image horizontally.
It maps the pixel at (x, y) to (width - 1 - x, y).
-}
flipHorizontal :: Image PixelRGB8 -> Image PixelRGB8
flipHorizontal img = generateImage generator w h
  where
    w = imageWidth img
    h = imageHeight img
    generator x y = pixelAt img (w - 1 - x) y

{- | Pixelates the image by grouping pixels into blocks.
It just grabs the top-left pixel of a 10x10 block and fills the block with it.
-}
pixelate :: Image PixelRGB8 -> Image PixelRGB8
pixelate img = generateImage generator w h
  where
    w = imageWidth img
    h = imageHeight img
    blockSize = 10 -- You could pass this as an argument later!
    generator x y =
        let nx = (x `div` blockSize) * blockSize
            ny = (y `div` blockSize) * blockSize
         in pixelAt img nx ny

{- | Box Blur (3x3 Neighborhood)
Takes a pixel, looks at its 8 immediate neighbors, and averages their colors.
-}
boxBlur :: Image PixelRGB8 -> Image PixelRGB8
boxBlur img = generateImage generator w h
  where
    w = imageWidth img
    h = imageHeight img

    -- Helper function to prevent crashing at the edges of the image.
    -- If it tries to look outside the image, it just clamps to the border.
    safePixel cx cy =
        let safeX = max 0 (min (w - 1) cx)
            safeY = max 0 (min (h - 1) cy)
         in pixelAt img safeX safeY

    generator x y =
        -- 1. Gather the 9 pixels in the 3x3 grid centered on (x, y)
        let pixels =
                [ safePixel (x + dx) (y + dy)
                  | dx <- [-1, 0, 1],
                    dy <- [-1, 0, 1]
                ]

            -- 2. Sum up the R, G, and B values separately
            sumR = sum [fromIntegral r | PixelRGB8 r _ _ <- pixels] :: Int
            sumG = sum [fromIntegral g | PixelRGB8 _ g _ <- pixels] :: Int
            sumB = sum [fromIntegral b | PixelRGB8 _ _ b <- pixels] :: Int

            count = length pixels
         in -- 3. Divide by 9 to get the average
            PixelRGB8
                (fromIntegral (sumR `div` count))
                (fromIntegral (sumG `div` count))
                (fromIntegral (sumB `div` count))

-- | Applies the selected filter to the whole image.
applyPureFilter :: FilterType -> Image PixelRGB8 -> Image PixelRGB8
applyPureFilter Invert img = pixelMap invertPixel img
applyPureFilter Grayscale img = pixelMap grayscalePixel img
applyPureFilter Sepia img = pixelMap sepiaPixel img
applyPureFilter Brighten img = pixelMap brightenPixel img
applyPureFilter Darken img = pixelMap darkenPixel img
applyPureFilter Threshold img = pixelMap thresholdPixel img
applyPureFilter ChannelSwap img = pixelMap channelSwapPixel img
-- New Advanced Filters:
applyPureFilter FlipHorizontal img = flipHorizontal img
applyPureFilter Pixelate img = pixelate img
applyPureFilter BoxBlur img = boxBlur img
applyPureFilter None img = img

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
                -- Look how much cleaner this line is now!
                filtered = applyPureFilter filterType rgbImage
            savePngImage outputPath (ImageRGB8 filtered)
            return (Right ())

-- | Simply copies a file (used for saving or resetting to None).
copyImage :: FilePath -> FilePath -> IO (Either String ())
copyImage src dest = do
    result <- try (copyFile src dest) :: IO (Either SomeException ())
    case result of
        Left err -> return $ Left (show err)
        Right _ -> return $ Right ()
