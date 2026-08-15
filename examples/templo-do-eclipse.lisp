(require :asdf)

(load (merge-pathnames #P"_bootstrap.lisp"
                       (uiop:pathname-directory-pathname *load-truename*)))

;;; --------------------------------------------------------------------------
;;; TEMPLO DO ECLIPSE
;;;
;;; Nao e uma arena fisica comum. Altares flutuam no vazio, sigilos orbitam um
;;; olho central e as leis do mundo mudam com o tempo de simulacao.
;;; --------------------------------------------------------------------------

(defun ilha-do-templo (nome x y z sx sy sz cor)
  (limiar3d:adicionar-entidade
   (limiar3d:criar-cubo
    :nome nome
    :posicao (limiar3d:v3 x y z)
    :escala (limiar3d:v3 sx sy sz)
    :cor cor
    :fisico-p t
    :dinamico-p nil
    :tags '(:templo :ilha))))

(defun cena-templo-do-eclipse ()
  (limiar3d:preparar-cena-vazia)
  (limiar3d:configurar-ambiente
   :hora 0.0
   :ciclo-dia-noite-p nil
   :gravidade -2.2
   :mostrar-grade-p nil
   :mostrar-eixos-p nil
   :cor-ceu (limiar3d:v3 0.045 0.012 0.075))
  (limiar3d:configurar-camera
   :posicao (limiar3d:v3 0.0 7.0 17.0)
   :rotacao (limiar3d:v3 -18.0 0.0 0.0))

  ;; Cinco altares separados: nao existe um piso global.
  (ilha-do-templo "altar-central" 0.0 -0.8 0.0 5.0 1.0 5.0
                   (limiar3d:v3 0.16 0.08 0.22))
  (ilha-do-templo "altar-norte" 0.0 0.5 -8.0 4.0 0.8 4.0
                   (limiar3d:v3 0.12 0.07 0.18))
  (ilha-do-templo "altar-sul" 0.0 1.0 8.0 4.0 0.8 4.0
                   (limiar3d:v3 0.12 0.07 0.18))
  (ilha-do-templo "altar-leste" 8.0 1.8 0.0 4.0 0.8 4.0
                   (limiar3d:v3 0.12 0.07 0.18))
  (ilha-do-templo "altar-oeste" -8.0 -0.2 0.0 4.0 0.8 4.0
                   (limiar3d:v3 0.12 0.07 0.18))

  ;; O olho do eclipse paira no centro e serve de foco visual.
  (let ((olho
          (limiar3d:adicionar-entidade
           (limiar3d:criar-piramide
            :nome "olho-do-eclipse"
            :posicao (limiar3d:v3 0.0 3.2 0.0)
            :escala (limiar3d:v3 2.2 2.2 2.2)
            :cor (limiar3d:v3 0.92 0.12 0.48)
            :velocidade-rotacao (limiar3d:v3 25.0 52.0 16.0)
            :tags '(:interagivel :metafisica)))))
    (limiar3d:adicionar-comportamento
     olho (limiar3d:comportamento-flutuar :altura 0.45 :velocidade 0.8)))

  ;; Doze sigilos formam um relogio orbital ao redor do centro.
  (dotimes (i 12)
    (let ((sigilo
            (limiar3d:adicionar-entidade
             (limiar3d:criar-piramide
              :nome (format nil "sigilo-~2,'0d" i)
              :posicao (limiar3d:v3 6.0 2.0 0.0)
              :escala (limiar3d:v3 0.38 0.65 0.38)
              :cor (if (evenp i)
                       (limiar3d:v3 0.56 0.22 0.90)
                       (limiar3d:v3 0.18 0.72 0.92))
              :velocidade-rotacao (limiar3d:v3 40.0 65.0 25.0)
              :tags '(:sigilo :metafisica)))))
      (limiar3d:adicionar-comportamento
       sigilo
       (limiar3d:comportamento-orbitar
        (limiar3d:v3 0.0 0.0 0.0)
        (+ 4.8 (* (mod i 3) 0.8))
        (+ 8.0 (* i 1.7))
        (+ 1.8 (* (mod i 4) 0.35))))))

  ;; Relicarios fisicos deixam a mudanca de gravidade visivel.
  (dotimes (i 8)
    (limiar3d:adicionar-entidade
     (limiar3d:criar-cubo
      :nome (format nil "relicario-~d" i)
      :posicao (limiar3d:v3 (- (* (mod i 4) 1.1) 1.7)
                            (+ 5.0 (* (floor i 4) 1.2))
                            (- (* (floor i 4) 1.2) 0.6))
      :escala (limiar3d:v3 0.5 0.5 0.5)
      :cor (limiar3d:v3 0.82 0.74 0.92)
      :fisico-p t :dinamico-p t :restituicao 0.15
      :tags '(:relicario :metafisica :fisica))))

  ;; Lei 1: depois de alguns segundos, o sentido da queda e invertido.
  (limiar3d:adicionar-regra
   (limiar3d:criar-regra
    "ascensao-dos-relicarios"
    (lambda () (> limiar3d::*tempo-mundo* 4.0))
    (lambda ()
      (setf (limiar3d::configuracao-motor-gravidade limiar3d:*configuracao*) 3.5)
      (format t "~&[lei] A queda deixou de apontar para baixo.~%"))
    :uma-vez-p t))

  ;; Lei 2: o vazio muda de cor como segunda fase do ritual.
  (limiar3d:adicionar-regra
   (limiar3d:criar-regra
    "segunda-fase-do-eclipse"
    (lambda () (> limiar3d::*tempo-mundo* 9.0))
    (lambda ()
      (setf (limiar3d::configuracao-motor-cor-ceu-fixa limiar3d:*configuracao*)
            (limiar3d:v3 0.10 0.015 0.018))
      (format t "~&[lei] O eclipse entrou na segunda fase.~%"))
    :uma-vez-p t))

  (format t "~&[ambiente] Templo do Eclipse carregado. Observe as leis mudarem.~%"))

(limiar3d:iniciar :construtor-cena #'cena-templo-do-eclipse)
