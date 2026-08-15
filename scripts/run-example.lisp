(require :asdf)

;;; Nomes antigos continuam aceitos para nao quebrar comandos de versoes anteriores.
(defparameter *aliases-de-exemplos*
  '(;; 0.2.6 e anteriores -> nome oficial atual
    ("demo-basico" . "observatorio-do-alvorecer")
    ("fisica" . "deposito-de-impacto")
    ("regras-metafisicas" . "templo-do-eclipse")
    ("cena-personalizada" . "arquipelago-suspenso")
    ("obj" . "galeria-do-monolito")))

(defun nome-oficial-do-exemplo (nome)
  (or (cdr (assoc nome *aliases-de-exemplos* :test #'string=))
      nome))

(let* ((args (uiop:command-line-arguments))
       (pedido (or (first args) "observatorio-do-alvorecer"))
       (nome (nome-oficial-do-exemplo pedido))
       (aqui (uiop:pathname-directory-pathname *load-truename*))
       (raiz (uiop:pathname-parent-directory-pathname aqui))
       (arquivo (merge-pathnames
                 (make-pathname :directory '(:relative "examples")
                                :name nome :type "lisp")
                 raiz)))
  (when (not (string= pedido nome))
    (format t "~&[Limiar 3D] '~a' e um alias legado; usando '~a'.~%"
            pedido nome))
  (unless (probe-file arquivo)
    (error "Exemplo desconhecido: ~a~%Nomes oficiais: observatorio-do-alvorecer, deposito-de-impacto, templo-do-eclipse, arquipelago-suspenso, galeria-do-monolito."
           pedido))
  (load arquivo))
