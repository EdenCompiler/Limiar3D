$Quicklisp = Join-Path $HOME "quicklisp/setup.lisp"
sbcl --load $Quicklisp --script run-tests.lisp
