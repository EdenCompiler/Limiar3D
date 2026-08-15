(require :asdf)

(load (merge-pathnames #P"_bootstrap.lisp"
                       (uiop:pathname-directory-pathname *load-truename*)))

;;; --------------------------------------------------------------------------
;;; OBSERVATORIO DO ALVORECER
;;;
;;; Uma cena clara e aberta, feita para apresentar navegacao, raycast,
;;; interacao e comportamentos sem reaproveitar a demo interna do motor.
;;; --------------------------------------------------------------------------

(defun cena-observatorio-do-alvorecer ()
  (limiar3d:preparar-cena-vazia)
  (limiar3d:configurar-ambiente
   :hora 7.0
   :ciclo-dia-noite-p nil
   :gravidade -9.81
   :mostrar-grade-p nil
   :mostrar-eixos-p nil
   :cor-ceu (limiar3d:v3 0.30 0.56 0.82))
  (limiar3d:configurar-camera
   :posicao (limiar3d:v3 0.0 3.1 14.5)
   :rotacao (limiar3d:v3 -8.0 0.0 0.0))

  ;; Praca central clara.
  (limiar3d:adicionar-entidade
   (limiar3d:criar-chao
    :nome "praca-de-pedra"
    :y -1.15 :largura 22.0 :profundidade 22.0 :espessura 0.45
    :cor (limiar3d:v3 0.42 0.48 0.52)))

  ;; Quatro pilares marcam os pontos cardeais da praca.
  (dolist (dados '((-6.0 0.0 "pilar-oeste")
                   ( 6.0 0.0 "pilar-leste")
                   ( 0.0 -6.0 "pilar-norte")
                   ( 0.0  6.0 "pilar-sul")))
    (destructuring-bind (x z nome) dados
      (limiar3d:adicionar-entidade
       (limiar3d:criar-cubo
        :nome nome
        :posicao (limiar3d:v3 x 1.0 z)
        :escala (limiar3d:v3 0.75 4.2 0.75)
        :cor (limiar3d:v3 0.72 0.76 0.78)
        :fisico-p t))))

  ;; O instrumento central pode ser ativado com F/clique curto.
  (let ((astrolabio
          (limiar3d:adicionar-entidade
           (limiar3d:criar-piramide
            :nome "astrolabio"
            :posicao (limiar3d:v3 0.0 0.35 0.0)
            :escala (limiar3d:v3 2.1 2.1 2.1)
            :cor (limiar3d:v3 0.95 0.72 0.18)
            :velocidade-rotacao (limiar3d:v3 0.0 16.0 0.0)
            :tags '(:interagivel :observatorio)))))
    (limiar3d:definir-dado astrolabio :ativo nil)
    (setf (limiar3d::entidade-ao-interagir astrolabio)
          (lambda (entidade)
            (let ((ativo (not (limiar3d:obter-dado entidade :ativo nil))))
              (limiar3d:definir-dado entidade :ativo ativo)
              (setf (limiar3d::entidade-cor entidade)
                    (if ativo
                        (limiar3d:v3 0.35 0.95 1.0)
                        (limiar3d:v3 0.95 0.72 0.18))
                    (limiar3d::entidade-velocidade-rotacao entidade)
                    (if ativo
                        (limiar3d:v3 18.0 75.0 12.0)
                        (limiar3d:v3 0.0 16.0 0.0)))
              (format t "~&[observatorio] Astrolabio ~:[desativado~;ativado~].~%"
                      ativo)))))

  ;; Pequenos marcadores orbitam o instrumento.
  (dotimes (i 4)
    (let ((orbe
            (limiar3d:adicionar-entidade
             (limiar3d:criar-cubo
              :nome (format nil "marcador-celeste-~d" i)
              :posicao (limiar3d:v3 (+ 3.0 i) 2.2 0.0)
              :escala (limiar3d:v3 0.35 0.35 0.35)
              :cor (limiar3d:v3 0.88 0.94 1.0)
              :velocidade-rotacao (limiar3d:v3 35.0 45.0 20.0)
              :tags '(:orbital :observatorio)))))
      (limiar3d:adicionar-comportamento
       orbe
       (limiar3d:comportamento-orbitar
        (limiar3d:v3 0.0 0.2 0.0)
        (+ 3.0 (* i 0.7))
        (+ 18.0 (* i 5.0))
        (+ 1.3 (* i 0.22))))))

  (format t "~&[ambiente] Observatorio do Alvorecer carregado.~%"))

(limiar3d:iniciar :construtor-cena #'cena-observatorio-do-alvorecer)
