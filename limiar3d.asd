(asdf:defsystem #:limiar3d
  :description "Limiar 3D - motor 3D didatico, hackeavel e single-file em Common Lisp"
  :author "Limiar 3D contributors"
  :license "MIT"
  :version "0.2.7"
  :depends-on (#:cl-opengl #:cl-glu #:cl-glut)
  :serial t
  :components ((:file "limiar3d"))
  :in-order-to ((test-op (test-op #:limiar3d/tests))))

(asdf:defsystem #:limiar3d/tests
  :description "Testes sem janela do Limiar 3D"
  :depends-on (#:limiar3d)
  :serial t
  :components ((:module "tests"
                :components ((:file "tests"))))
  :perform (test-op (op system)
             (declare (ignore op system))
             (unless (uiop:symbol-call '#:limiar3d.tests '#:run-tests)
               (error "Os testes do Limiar 3D falharam."))))
