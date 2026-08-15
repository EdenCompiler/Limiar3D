# Testes

A suíte foi desenhada para rodar sem abrir uma janela GLUT. Ela valida partes do motor que podem ser verificadas de forma determinística, incluindo matemática, coerência da câmera, AABBs, metadados, regras, preparação de cena vazia, céu fixo e câmera inicial por ambiente.

```sh
sbcl --load ~/quicklisp/setup.lisp --script run-tests.lisp
```

Os bindings OpenGL ainda precisam estar instalados porque o pacote principal é carregado durante os testes.
