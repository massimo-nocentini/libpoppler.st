# libpoppler.st

uFFI bindings to [Poppler](https://poppler.freedesktop.org/)'s GLib interface (poppler-glib) for
[Pharo](https://pharo.org) 12, 13, 14 and 15: open PDF documents from files or bytes (encrypted ones with their
password), read page sizes, labels, metadata and text, render pages on Athens' cairo canvas or into a Form, and show
them as Roassal shapes. No VM plugin and no primitive: every call is a uFFI callout.

## The libraries

The bindings load `libpoppler-glib` by its soname (macOS: install name, Windows: MSYS2 DLL name), and GLib/GObject
through the `GLib` group of [libpangocairo.st](https://github.com/massimo-nocentini/libpangocairo.st), with uFFI's
finders: the image directory, the VM directory or bundle, then the system's paths.

- **The VM of [massimo-nocentini/pharo-vm](https://github.com/massimo-nocentini/pharo-vm)** carries them in its cairo
  stack (`FEATURE_LIB_POPPLER`, on by default): Poppler 26.11 and GLib 2.90, next to the cairo 1.18.6 that Athens uses,
  on Linux x86_64/aarch64, macOS and Windows. On Linux the stack needs glibc 2.38 or later. Nothing has to be copied
  next to the image any more; delete the DLLs that the previous README told Windows users to copy there.
- **Another VM** uses the system's libraries (Linux distributions, Homebrew): one GLib ≥ 2.88 and a poppler-glib linked
  to the same libcairo as Athens.

## Loading

```Smalltalk
Metacello new
	baseline: 'LibPoppler';
	repository: 'github://massimo-nocentini/libpoppler.st:master/src';
	load.
```

`load` loads the `default` group; `load: #( 'Core' )` only the core. The baseline loads only the `GLib` group of
libpangocairo.st (LibGLib, LibGLib-Cairo); Athens and Roassal come with the stock images.

| Group | Packages |
|---|---|
| `Core` | `LibPoppler`: `PopplerDocument`, `PopplerPage`, `AthensCairoCanvas>>drawPopplerPage:`, `FileReference>>asPdf` |
| `Roassal` | `Core` + `LibPoppler-Roassal`: `RSPdfPage`, `PopplerPage>>asRoassalShape`, `PopplerDocument>>asRoassalShapes` |
| `Examples` | `LibPoppler-Examples`: `PopplerExamples` (class-side `<example>`s) |
| `Tests`, `RoassalTests` | the tests of each layer (the Roassal tests reuse the fixtures of `Tests`) |
| `default` | all of the above |

## The API in 10 lines

```Smalltalk
document := PopplerDocument fromFile: 'paper.pdf'.               "or fromBytes:, or 'paper.pdf' asFileReference asPdf"
document pageCount. document title. document author.             "title and author are nil when absent"
page := document pageAt: 1.                                       "1-based, cached; pages, pagesDo:, pageLabeled: 'iv'"
page size. page label. page text.                                 "size in PDF points; text in UTF-8"
form := page asFormScale: 2.                                      "a Form on a white background, 2 pixels per point"
surface := AthensCairoSurface extent: page size ceiling.
surface drawDuring: [ :canvas | canvas drawPopplerPage: page ].   "top-left at the origin of the canvas' transformation"
secret := PopplerDocument fromFile: 'secret.pdf' password: 'pw'.  "PopplerError isEncrypted without it"
canvas := RSCanvas new. canvas addAll: document asRoassalShapes.  "one RSPdfPage per page"
RSGridLayout on: canvas nodes. canvas open.
```

`asPdf pages` now answers `PopplerPage`s, no longer Roassal shapes: use `asRoassalShapes` for those. A document that
cannot be opened signals `PopplerError` (`isEncrypted` for a missing or wrong password, `isDamaged`/`isInvalid` for bytes
that are not a PDF, `isOpenFile`), never a crash.

## Units

1 unit of the canvas is 1 PDF point: a page draws at its size in points (`page size`), with its top-left corner at the
origin of the canvas' current transformation; scale the canvas (or use `asFormScale:`) for another resolution. No
background is painted by `drawPopplerPage:`; `RSPdfPage` paints a white one unless `showsBackground: false`.

## Memory, sessions and reopening

1. Documents and pages are freed by finalization when unreachable; `release` frees one at once.
2. A page holds a reference on its document in C, so they can be collected in any order.
3. `copy` takes a new reference; each copy is freed on its own.
4. Documents and pages survive an image restart: the first use in a new session reopens them. A document opened from
   a file re-reads that file (it keeps the FileReference, its size and modification time, never the bytes) and signals
   `PopplerError isOpenFile` when the file vanished or changed; one opened from bytes keeps the bytes. Pages are
   refetched by index. So an `RSPdfPage` in a saved canvas redraws after a restart.
5. Passwords are kept for the current session only and never written into a snapshot: after a restart an encrypted
   document signals `PopplerError isEncrypted` until it gets `password:` again.
6. One GLib per process: when a library linking another GLib (a GTK-based plugin, say) was loaded first, the bindings
   refuse with `GLibInstanceMismatch` instead of crashing; poppler-glib must also use Athens' libcairo.

## Tests and CI

```sh
LIBPANGOCAIRO_DIR=../libpangocairo.st sh ci/run.sh <vm-dir> <Pharo image .zip or .image>
```

copies the image, loads the `GLib` group of the libpangocairo.st checkout in `LIBPANGOCAIRO_DIR` (by default
`../libpangocairo.st` next to this one) and locks `LibPangoCairo` there, then loads this checkout's baseline with
Metacello (`tonel://`, no network), checks that the loaded packages have no undeclared variable, no unimplemented
selector and no callout that bypasses `validHandle`, runs every test and prints
`LibPoppler <pharo> loaded <groups> tests <n> passed <p> skipped <s> failed <f> errors <e> poppler <version> ok`.
`PHARO_CAIRO_STACK_EXPECT_LIBS=yes` (its default) makes a missing library a failure instead of a skip;
`POPPLER_EXPECT_VERSION` checks the version found; `CI_GROUPS` chooses the groups (by default `Core Tests`, plus
`Roassal RoassalTests Examples` when the image has Roassal). The test PDFs are made at run time (cairo, or written in
Smalltalk for the encrypted and base-14 ones): there is no fixture file.

## Removed

The previous version is master fbd0386; everything below can be recovered from it.

- `dlls/` (an incomplete 2023 Windows build that would replace the VM's cairo and FreeType) and
  `pbe-object-model.pdf`.
- `PopplerPdf` and its `compile:TeX:times:`/`compileTeX:times:`, the TeX/TikZ chunks (`TPopplerStandaloneTeXBuilder`,
  `PopplerTeXChunk`, `PopplerTeXDisplayStyleChunk`, `PopplerTikZChunk`), the Calypso tabs (`RSUMLClassPdfCalypso`,
  `RSUMLClassTexCommentCalypso`), `LibPopplerTestCase`.
- `GLibLibrary` and `GObjectLibrary` (now in libpangocairo.st's LibGLib), `AthensCairoCanvas>>renderPopplerPageHandle:ofPdfPage:`
  (now `drawPopplerPage:`), the old `RSPdfPage` (rewritten in LibPoppler-Roassal).

## Deferred

- WebAssembly: the wasm VM has no GLib or Poppler yet.
- Poppler API beyond the above: annotations, forms, links and outline, attachments, find and selection, signatures,
  layers, media, saving, per-area text and text layout, metadata beyond title and author, thumbnails.
- The TeX/TikZ chunks and the Calypso tabs.

## Licence

MIT (see `LICENSE`). Poppler is GPL-2.0-or-later, distributed in the VM under GPL-3.0; this MIT binding loads it
dynamically; whoever distributes a program using it should read the GPL. `-DFEATURE_LIB_POPPLER=OFF` builds a VM without
it. GLib is under the LGPL; the VM's notices list every bundled library.
