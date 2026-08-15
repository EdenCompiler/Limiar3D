param([string]$Exemplo = "observatorio-do-alvorecer")
$Quicklisp = Join-Path $HOME "quicklisp/setup.lisp"
sbcl --load $Quicklisp --script scripts/run-example.lisp $Exemplo
