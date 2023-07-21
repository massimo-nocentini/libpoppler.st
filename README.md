# libpoppler.st

Bindings to the [Poppler library](https://poppler.freedesktop.org/) for Pharo Smalltalk, load it with

```smalltalk
Metacello new
    baseline: 'LibPoppler';
    repository: 'github://massimo-nocentini/LibPoppler.st';
    load
```

To use it under **Windowns** please let the libraries contained in the `dlls` directory be reachable from the Pharo process: it is sufficient to copy the either in the same folder of the Pharo image or in the folder of the VM used to run your image.
