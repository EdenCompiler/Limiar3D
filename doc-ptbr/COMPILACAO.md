# Compilação e instalação

## Dependências

- uma implementação Common Lisp; o fluxo documentado usa SBCL;
- ASDF;
- Quicklisp recomendado;
- `cl-opengl`, `cl-glu`, `cl-glut`;
- OpenGL e FreeGLUT do sistema.

## Debian/Ubuntu

```sh
sudo apt update
sudo apt install sbcl freeglut3-dev libgl1-mesa-dev
```

Depois de instalar Quicklisp:

```sh
sbcl --load ~/quicklisp/setup.lisp --load quickstart.lisp --eval '(limiar3d:iniciar)'
```

## ASDF

Se o checkout estiver em um diretório conhecido pelo ASDF:

```lisp
(ql:quickload :limiar3d)
(limiar3d:iniciar)
```

Ou carregue o `.asd` diretamente:

```lisp
(asdf:load-asd #P"/caminho/limiar3d.asd")
(asdf:load-system :limiar3d)
```

## Carregamento single-file

O próprio `limiar3d.lisp` tenta usar Quicklisp quando os pacotes OpenGL ainda não estão carregados. Por isso o fluxo antigo continua válido:

```sh
sbcl --load ~/quicklisp/setup.lisp --load limiar3d.lisp --eval '(limiar3d:iniciar)'
```

## Testes

```sh
sbcl --load ~/quicklisp/setup.lisp --script run-tests.lisp
```

Os testes não abrem janela, mas ainda carregam os bindings OpenGL.

## Observação sobre distribuição

Esta versão documenta o desenvolvimento a partir do source/ASDF. Empacotamento nativo de executáveis ainda não é parte suportada da release.

## SBCL e `DEFCONSTANT-UNEQL`

A partir da v0.2.5, o Limiar 3D evita `DEFCONSTANT` direto para strings de identidade/versao. O SBCL segue estritamente a regra ANSI de que uma redefinicao de constante so e definida quando o novo valor e `EQL` ao anterior. Como strings iguais nao precisam ser `EQL`, compilar e carregar o mesmo arquivo podia falhar.

O motor usa `DEFINIR-CONSTANTE` para esses valores compostos, preservando o objeto ja ligado quando necessario.
