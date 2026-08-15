(require :asdf)

(load (merge-pathnames #P"_bootstrap.lisp"
                       (uiop:pathname-directory-pathname *load-truename*)))

;;; --------------------------------------------------------------------------
;;; DEPOSITO DE IMPACTO
;;;
;;; Um galpao industrial pesado: paredes, docas, pilhas de carga e dezenas de
;;; corpos dinamicos. Aqui o ambiente existe para estressar gravidade e AABB.
;;; --------------------------------------------------------------------------

(defun bloco-industrial (nome x y z sx sy sz cor)
  (limiar3d:adicionar-entidade
   (limiar3d:criar-cubo
    :nome nome
    :posicao (limiar3d:v3 x y z)
    :escala (limiar3d:v3 sx sy sz)
    :cor cor
    :fisico-p t
    :dinamico-p nil
    :tags '(:cenario :industrial))))

(defun cena-deposito-de-impacto ()
  (limiar3d:preparar-cena-vazia)
  (limiar3d:configurar-ambiente
   :hora 23.0
   :ciclo-dia-noite-p nil
   :gravidade -14.5
   :mostrar-grade-p nil
   :mostrar-eixos-p nil
   :cor-ceu (limiar3d:v3 0.025 0.030 0.045))
  (limiar3d:configurar-camera
   :posicao (limiar3d:v3 11.5 6.5 15.0)
   :rotacao (limiar3d:v3 -17.0 -34.0 0.0))

  ;; Piso e paredes formam um ambiente fechado, bem diferente da praca aberta.
  (bloco-industrial "piso-do-galpao" 0.0 -1.3 0.0 24.0 0.5 28.0
                    (limiar3d:v3 0.16 0.17 0.18))
  (bloco-industrial "parede-fundo" 0.0 4.0 -13.5 24.0 10.0 0.5
                    (limiar3d:v3 0.10 0.11 0.13))
  (bloco-industrial "parede-esquerda" -11.8 4.0 0.0 0.5 10.0 28.0
                    (limiar3d:v3 0.11 0.12 0.14))
  (bloco-industrial "parede-direita" 11.8 4.0 0.0 0.5 10.0 28.0
                    (limiar3d:v3 0.11 0.12 0.14))

  ;; Docas elevadas e separadores de carga.
  (dotimes (i 3)
    (bloco-industrial
     (format nil "doca-~d" i)
     (- (* i 7.0) 7.0) 0.1 -8.5
     5.0 2.2 4.0
     (limiar3d:v3 0.23 0.25 0.27)))

  ;; Pilhas de carga inicialmente organizadas.
  (dotimes (coluna 4)
    (dotimes (nivel 4)
      (limiar3d:adicionar-entidade
       (limiar3d:criar-cubo
        :nome (format nil "carga-~d-~d" coluna nivel)
        :posicao (limiar3d:v3 (- (* coluna 1.25) 5.5)
                              (+ -0.5 (* nivel 1.05))
                              4.0)
        :escala (limiar3d:v3 0.95 0.95 0.95)
        :cor (if (evenp (+ coluna nivel))
                 (limiar3d:v3 0.92 0.42 0.12)
                 (limiar3d:v3 0.16 0.48 0.72))
        :fisico-p t
        :dinamico-p t
        :restituicao 0.04
        :atrito 0.28
        :tags '(:carga :fisica)))))

  ;; Uma chuva de contenedores cai de alturas e posicoes deterministicas.
  (dotimes (i 16)
    (let* ((faixa (mod i 4))
           (linha (floor i 4))
           (x (- (* faixa 2.2) 3.3))
           (z (- (* linha 2.0) 3.0))
           (y (+ 7.0 (* i 0.72))))
      (limiar3d:adicionar-entidade
       (limiar3d:criar-cubo
        :nome (format nil "contenedor-caindo-~2,'0d" i)
        :posicao (limiar3d:v3 x y z)
        :escala (limiar3d:v3 1.25 0.65 0.85)
        :cor (limiar3d:v3 0.62 0.68 0.72)
        :velocidade-rotacao (limiar3d:v3 (* 7.0 i) 18.0 (* 3.0 i))
        :fisico-p t
        :dinamico-p t
        :restituicao 0.10
        :atrito 0.22
        :tags '(:contenedor :fisica)))))

  (format t "~&[ambiente] Deposito de Impacto carregado. Gravidade = -14.5.~%"))

(limiar3d:iniciar :construtor-cena #'cena-deposito-de-impacto)
