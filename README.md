# hask-image

A small Haskell image filtering tool with a GUI. Built on Monomer for the interface and JuicyPixels for image work.

The code is intentionally minimal. If you've been meaning to poke at functional GUI code in Haskell, this is a reasonable place to start.

---

## Running the app

You need `stack`. Grab it from [haskellstack.org](https://docs.haskellstack.org/en/stable/README/) if you don't have it.

Monomer pulls in two C libraries: SDL2 and GLEW.

### Windows
With `stack`, MSYS2 handles most of this. Run:
```bash
stack setup
```
If the C libraries give you trouble, see the [Monomer Windows setup guide](https://github.com/fjvallarino/monomer#windows).

### macOS
```bash
brew install sdl2 glew
stack build
stack exec hask-image-exe
```

### Linux (Ubuntu/Debian)
```bash
sudo apt install libsdl2-dev libglew-dev
stack build
stack exec hask-image-exe
```

---

## Project layout

* `app/Main.hs` - entry point. Sets up the window, fonts, and the Monomer loop.
* `src/Types.hs` - the `AppModel` (state) and `AppEvent` (anything that can happen, e.g. button clicks).
* `src/UI.hs` - the widget tree and event handler. Routes events to model updates or background tasks.
* `src/Filter.hs` - pure pixel transformations and the I/O wrappers that load and save images.
* `assets/` - the Roboto font and a sample image.

---

## Adding a new filter

The filter functions in `src/Filter.hs` are pure: they take a `PixelRGB8` and hand back a new one. Nothing about the UI or the filesystem leaks in. Adding a new filter is mostly bookkeeping.

### 1. Write the pixel function

Look at `invertPixel` for the shape:
```haskell
invertPixel :: PixelRGB8 -> PixelRGB8
invertPixel (PixelRGB8 r g b) = PixelRGB8 (255 - r) (255 - g) (255 - b)
```
A filter that drops the red channel:
```haskell
removeRedPixel :: PixelRGB8 -> PixelRGB8
removeRedPixel (PixelRGB8 _ g b) = PixelRGB8 0 g b
```

### 2. Register it in `FilterType`

In `src/Types.hs`, add a constructor to `FilterType`. Because the dropdown enumerates `[minBound .. maxBound]`, that's all the UI needs.
```haskell
data FilterType
  = None
  | Invert
  | ...
  | RemoveRed
```

### 3. Wire it into `getFilterFunc`

Back in `src/Filter.hs`:
```haskell
getFilterFunc RemoveRed = removeRedPixel
```

That's the whole loop. The dropdown picks it up, the existing `FilterSelected` handler runs the pure function over the image, and the result is written to a temp file for display.

---

## Built-in filters

* `Invert` - inverts each channel.
* `Grayscale` - luminance-weighted average.
* `Sepia` - the classic warm brown tone via the standard 3x3 matrix.
* `Brighten` / `Darken` - shifts every channel by a fixed amount, clamped.
* `Threshold` - black-and-white at luminance 128.
* `ChannelSwap` - rotates RGB to BRG. Useful for a quick "weird" look.
