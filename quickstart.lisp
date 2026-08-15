;;;; quickstart.lisp -- carrega o Limiar 3D a partir do checkout atual.

(require :asdf)

(defun diretorio-deste-arquivo ()
  (uiop:pathname-directory-pathname
   (or *load-truename* *compile-file-truename* *default-pathname-defaults*)))

(let* ((raiz (diretorio-deste-arquivo))
       (asd (merge-pathnames #P"limiar3d.asd" raiz)))
  ;; Se Quicklisp estiver disponivel, pedimos somente as dependencias. O sistema
  ;; LIMIAR3D em si e sempre carregado pelo .asd deste checkout, evitando que um
  ;; sistema homonimo registrado em outro lugar seja escolhido por acidente.
  (when (find-package "QL")
    (funcall (symbol-function (intern "QUICKLOAD" "QL"))
             '(:cl-opengl :cl-glu :cl-glut)))

  (asdf:load-asd asd)
  (handler-case
      (asdf:load-system :limiar3d)
    (asdf:missing-dependency (erro)
      (error "~a~%Carregue Quicklisp ou instale as dependencias ASDF: cl-opengl, cl-glu e cl-glut."
             erro))))

(format t "~&Limiar 3D carregado. Execute (limiar3d:iniciar).~%")
