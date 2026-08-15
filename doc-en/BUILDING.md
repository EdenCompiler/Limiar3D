# Building and installation

Limiar 3D currently targets source/ASDF development. The documented implementation is SBCL.

## Debian/Ubuntu

```sh
sudo apt install sbcl freeglut3-dev libgl1-mesa-dev
```

With Quicklisp installed:

```sh
sbcl --load ~/quicklisp/setup.lisp --load quickstart.lisp --eval '(limiar3d:iniciar)'
```

## ASDF

```lisp
(asdf:load-asd #P"/path/to/limiar3d.asd")
(ql:quickload :limiar3d)
```

## Tests

```sh
sbcl --load ~/quicklisp/setup.lisp --script run-tests.lisp
```

Tests do not create a graphics window, although the OpenGL binding systems are still loaded.

## SBCL and `DEFCONSTANT-UNEQL`

Since v0.2.5, Limiar 3D avoids plain `DEFCONSTANT` for string identity/version values. SBCL strictly follows the ANSI rule that redefining a constant is only defined when the new value is `EQL` to the previous one. Equal strings are not necessarily `EQL`, so compiling and loading the same file could fail.

The engine uses `DEFINIR-CONSTANTE` for those compound values, preserving the already-bound object when required.
