(require :asdf)

(load (merge-pathnames #P"_bootstrap.lisp"
                       (uiop:pathname-directory-pathname *load-truename*)))

;;; --------------------------------------------------------------------------
;;; ARQUIPELAGO SUSPENSO
;;;
;;; Exemplo de autoria de mundo: ilhas independentes em alturas diferentes,
;;; pontes estreitas, torres e cristais. Nao existe um chao global.
;;; --------------------------------------------------------------------------

(defun ilha-flutuante (nome x y z largura profundidade cor)
  (limiar3d:adicionar-entidade
   (limiar3d:criar-cubo
    :nome nome
    :posicao (limiar3d:v3 x y z)
    :escala (limiar3d:v3 largura 0.9 profundidade)
    :cor cor
    :fisico-p t
    :dinamico-p nil
    :tags '(:ilha :cenario))))

(defun ponte-aerea (nome x y z sx sz)
  (limiar3d:adicionar-entidade
   (limiar3d:criar-cubo
    :nome nome
    :posicao (limiar3d:v3 x y z)
    :escala (limiar3d:v3 sx 0.22 sz)
    :cor (limiar3d:v3 0.48 0.34 0.20)
    :fisico-p t
    :dinamico-p nil
    :tags '(:ponte :cenario))))

(defun cena-arquipelago-suspenso ()
  (limiar3d:preparar-cena-vazia)
  (limiar3d:configurar-ambiente
   :hora 15.0
   :ciclo-dia-noite-p nil
   :gravidade -6.0
   :mostrar-grade-p nil
   :mostrar-eixos-p nil
   :cor-ceu (limiar3d:v3 0.42 0.74 0.92))
  (limiar3d:configurar-camera
   :posicao (limiar3d:v3 -13.0 9.0 18.0)
   :rotacao (limiar3d:v3 -20.0 34.0 0.0))

  ;; Cinco ilhas em niveis diferentes.
  (ilha-flutuante "ilha-central" 0.0 2.0 0.0 7.0 7.0
                   (limiar3d:v3 0.28 0.46 0.25))
  (ilha-flutuante "ilha-do-farol" 9.0 5.0 -4.0 5.0 5.0
                   (limiar3d:v3 0.35 0.50 0.28))
  (ilha-flutuante "ilha-baixa" -8.0 -0.5 -5.0 6.0 4.5
                   (limiar3d:v3 0.24 0.40 0.24))
  (ilha-flutuante "ilha-jardim" -7.0 5.5 7.0 5.0 6.0
                   (limiar3d:v3 0.31 0.52 0.29))
  (ilha-flutuante "ilha-agulha" 7.5 8.0 8.5 4.0 4.0
                   (limiar3d:v3 0.30 0.43 0.25))

  ;; Pontes nao tentam conectar tudo: o jogador precisa usar Q/E em alguns trechos.
  (ponte-aerea "ponte-central-leste" 4.8 3.55 -2.0 5.0 0.75)
  (ponte-aerea "ponte-central-oeste" -4.2 0.9 -2.5 4.6 0.70)
  (ponte-aerea "ponte-jardim" -4.0 4.0 4.1 4.5 0.70)

  ;; Farol na ilha alta.
  (limiar3d:adicionar-entidade
   (limiar3d:criar-cubo
    :nome "torre-do-farol"
    :posicao (limiar3d:v3 9.0 8.0 -4.0)
    :escala (limiar3d:v3 1.2 6.0 1.2)
    :cor (limiar3d:v3 0.80 0.76 0.64)
    :fisico-p t))
  (let ((luz
          (limiar3d:adicionar-entidade
           (limiar3d:criar-piramide
            :nome "luz-do-farol"
            :posicao (limiar3d:v3 9.0 11.4 -4.0)
            :escala (limiar3d:v3 1.2 1.2 1.2)
            :cor (limiar3d:v3 1.0 0.88 0.28)
            :velocidade-rotacao (limiar3d:v3 0.0 55.0 0.0)
            :tags '(:farol :interagivel)))))
    (limiar3d:adicionar-comportamento
     luz (limiar3d:comportamento-flutuar :altura 0.22 :velocidade 1.1)))

  ;; Bosque de cristais na ilha-jardim.
  (dotimes (i 7)
    (limiar3d:adicionar-entidade
     (limiar3d:criar-piramide
      :nome (format nil "cristal-do-jardim-~d" i)
      :posicao (limiar3d:v3 (+ -8.5 (* (mod i 4) 1.0))
                            (+ 7.2 (* (mod i 2) 0.25))
                            (+ 5.7 (* (floor i 4) 1.2)))
      :escala (limiar3d:v3 0.5 (+ 1.3 (* 0.15 i)) 0.5)
      :cor (limiar3d:v3 0.42 0.88 0.76)
      :velocidade-rotacao (limiar3d:v3 0.0 (+ 4.0 i) 0.0)
      :tags '(:cristal :jardim))))

  ;; Pequeno enxame que circula a ilha-agulha.
  (dotimes (i 5)
    (let ((passaro
            (limiar3d:adicionar-entidade
             (limiar3d:criar-cubo
              :nome (format nil "planador-~d" i)
              :posicao (limiar3d:v3 10.0 11.0 8.5)
              :escala (limiar3d:v3 0.45 0.12 0.7)
              :cor (limiar3d:v3 0.92 0.95 0.96)
              :tags '(:planador)))))
      (limiar3d:adicionar-comportamento
       passaro
       (limiar3d:comportamento-orbitar
        (limiar3d:v3 7.5 8.0 8.5)
        (+ 2.5 (* i 0.45))
        (+ 22.0 (* i 3.5))
        (+ 2.0 (* i 0.25))))))

  (format t "~&[ambiente] Arquipelago Suspenso carregado. Use Q/E para explorar alturas.~%"))

(limiar3d:iniciar :construtor-cena #'cena-arquipelago-suspenso)
