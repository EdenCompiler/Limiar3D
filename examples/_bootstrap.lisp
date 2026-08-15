(require :asdf)

(defun raiz-do-projeto ()
  (let* ((arquivo (or *load-truename* *compile-file-truename*
                      *default-pathname-defaults*))
         (pasta-exemplo (uiop:pathname-directory-pathname arquivo)))
    (uiop:pathname-parent-directory-pathname pasta-exemplo)))

(load (merge-pathnames #P"quickstart.lisp" (raiz-do-projeto)))
