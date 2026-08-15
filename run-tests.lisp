;;;; run-tests.lisp -- entrada simples para CI e desenvolvimento local.

(require :asdf)

(let* ((aqui (uiop:pathname-directory-pathname
              (or *load-truename* *compile-file-truename*
                  *default-pathname-defaults*)))
       (asd (merge-pathnames #P"limiar3d.asd" aqui)))
  (when (find-package "QL")
    (funcall (symbol-function (intern "QUICKLOAD" "QL"))
             '(:cl-opengl :cl-glu :cl-glut)))

  (asdf:load-asd asd)
  (handler-case
      (asdf:test-system :limiar3d)
    (asdf:missing-dependency (erro)
      (error "~a~%Carregue Quicklisp ou instale as dependencias ASDF: cl-opengl, cl-glu e cl-glut."
             erro))))
