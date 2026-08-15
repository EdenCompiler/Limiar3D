#!/usr/bin/env sh
set -eu
exec sbcl --load "$HOME/quicklisp/setup.lisp" --script run-tests.lisp
