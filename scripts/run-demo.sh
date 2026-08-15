#!/usr/bin/env sh
set -eu
EXEMPLO="${1:-observatorio-do-alvorecer}"
exec sbcl --load "$HOME/quicklisp/setup.lisp" --script scripts/run-example.lisp "$EXEMPLO"
