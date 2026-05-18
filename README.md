# hask-image

A simple, modular Haskell-based Image Filtering tool with a graphical user interface (GUI). 

This project uses **Monomer** for the user interface and **JuicyPixels** for image processing. It is designed to be "stupid simple" and serves as an excellent starting point for beginners exploring functional programming and GUI development in Haskell.

---

## 🚀 How to Run the App

To run this application, you need to have `stack` installed on your machine.
If you don't have it, get it from [haskellstack.org](https://docs.haskellstack.org/en/stable/README/).

You also need the C libraries that Monomer depends on (SDL2 and GLEW).

### Windows
If you use `stack`, MSYS2 handles most dependencies automatically. You may need to run:
```bash
stack setup
```
If you experience issues with C libraries, consult the [Monomer Windows Setup Guide](https://github.com/fjvallarino/monomer#windows).

### macOS
Install the required libraries using Homebrew:
```bash
brew install sdl2 glew
stack build
stack exec hask-image-exe
```

### Linux (Ubuntu/Debian)
Install the required libraries using APT:
```bash
sudo apt install libsdl2-dev libglew-dev
stack build
stack exec hask-image-exe
```

---

## 📂 Project Structure

This project follows a clean, modular architecture:

* `app/Main.hs` - **The Engine Room**: The entry point of the app. It initializes the window, loads the fonts, and starts the Monomer loop.
* `src/Types.hs` - **The Brain**: Defines the `AppModel` (the state of the app) and `AppEvent` (the actions that can occur, like button clicks).
* `src/UI.hs` - **The Face**: Defines the layout of the GUI using Monomer widgets and handles events (routing them to update the model or run background tasks).
* `src/Filter.hs` - **The Lab**: The pure functional heart of the app. It contains the mathematical logic for transforming pixels and the I/O wrappers for saving/loading images.
* `assets/` - Contains required fonts (`Roboto`) and a sample image (`sample.png`).

---

## 🛠 Developer Notes: How to Add More Filters

One of the best things about Functional Programming is how easy it is to compose and extend pure functions. 

The image processing is deliberately kept "Pure" in `src/Filter.hs`. This means the filter functions do not know anything about the UI, the window, or the file system. They simply take a color (`PixelRGB8`) and return a new color.

### 1. Write the Pure Logic
Open `src/Filter.hs`. Notice how simple the invert filter is:
```haskell
invertPixel :: PixelRGB8 -> PixelRGB8
invertPixel (PixelRGB8 r g b) = PixelRGB8 (255 - r) (255 - g) (255 - b)
```
To add a new filter (e.g., stripping out the red channel), you just write another pure function:
```haskell
removeRedPixel :: PixelRGB8 -> PixelRGB8
removeRedPixel (PixelRGB8 r g b) = PixelRGB8 0 g b
```

### 2. Export the I/O Wrapper
Still in `src/Filter.hs`, create a wrapper that uses your new function with our `applyFilterToPath` helper, and add it to the module exports at the top of the file:
```haskell
applyRemoveRed :: FilePath -> FilePath -> IO (Either String ())
applyRemoveRed = applyFilterToPath removeRedPixel
```

### 3. Add an Event
Open `src/Types.hs`. Add a new event to the `AppEvent` data type:
```haskell
data AppEvent
  = ...
  | ApplyRemoveRedFilter
```

### 4. Update the UI
Open `src/UI.hs`.
1. Add a button to the `buildUI` function: 
   `button "Remove Red" ApplyRemoveRedFilter`
2. Add a new case in the `handleEvent` function to trigger your background task:
   ```haskell
   ApplyRemoveRedFilter ->
     let inPath = model ^. currentImagePath
         outPath = "output_nored.png"
         task = do
           res <- applyRemoveRed (unpack inPath) (unpack outPath)
           case res of
             Left err -> return (ErrorOccurred (pack err))
             Right _ -> return (FilterFinished outPath)
     in [Task task]
   ```

That's it! Your new filter is fully integrated.
