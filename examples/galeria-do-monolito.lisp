(require :asdf)

(load (merge-pathnames #P"_bootstrap.lisp"
                       (uiop:pathname-directory-pathname *load-truename*)))

;;; --------------------------------------------------------------------------
;;; GALERIA DO MONOLITO
;;;
;;; Um pequeno museu fechado. A geometria arquitetonica usa primitivas do
;;; motor, enquanto as pecas de exposicao sao carregadas de arquivos OBJ.
;;; --------------------------------------------------------------------------

(defun parede-galeria (nome x y z sx sy sz cor)
  (limiar3d:adicionar-entidade
   (limiar3d:criar-cubo
    :nome nome
    :posicao (limiar3d:v3 x y z)
    :escala (limiar3d:v3 sx sy sz)
    :cor cor
    :fisico-p t
    :dinamico-p nil
    :tags '(:galeria :arquitetura))))

(defun cena-galeria-do-monolito ()
  (limiar3d:preparar-cena-vazia)
  (limiar3d:configurar-ambiente
   :hora 20.0
   :ciclo-dia-noite-p nil
   :gravidade -9.81
   :mostrar-grade-p nil
   :mostrar-eixos-p nil
   :cor-ceu (limiar3d:v3 0.055 0.025 0.040))
  (limiar3d:configurar-camera
   :posicao (limiar3d:v3 0.0 2.2 15.5)
   :rotacao (limiar3d:v3 -4.0 0.0 0.0))

  ;; Sala longa com piso, teto e paredes laterais.
  (parede-galeria "piso-da-galeria" 0.0 -1.2 -2.0 14.0 0.45 34.0
                  (limiar3d:v3 0.17 0.15 0.16))
  (parede-galeria "teto-da-galeria" 0.0 6.8 -2.0 14.0 0.35 34.0
                  (limiar3d:v3 0.09 0.08 0.10))
  (parede-galeria "parede-esquerda" -6.8 2.8 -2.0 0.35 8.0 34.0
                  (limiar3d:v3 0.13 0.10 0.12))
  (parede-galeria "parede-direita" 6.8 2.8 -2.0 0.35 8.0 34.0
                  (limiar3d:v3 0.13 0.10 0.12))
  (parede-galeria "parede-final" 0.0 2.8 -18.7 14.0 8.0 0.35
                  (limiar3d:v3 0.10 0.08 0.10))

  ;; Pedestais laterais deixam o corredor visualmente museologico.
  (dolist (x '(-4.2 4.2))
    (dolist (z '(4.0 -2.0 -8.0 -14.0))
      (parede-galeria
       (format nil "pedestal-~,1f-~,1f" x z)
       x -0.35 z 1.7 1.5 1.7
       (limiar3d:v3 0.30 0.27 0.29))))

  (let* ((raiz (raiz-do-projeto))
         (arquivo-monolito
           (merge-pathnames #P"assets/modelos/monolito.obj" raiz))
         (arquivo-cristal
           (merge-pathnames #P"assets/modelos/cristal.obj" raiz))
         (malha-monolito
           (limiar3d:carregar-obj arquivo-monolito :nome "monolito"))
         (malha-cristal
           (limiar3d:carregar-obj arquivo-cristal :nome "cristal")))

    ;; Peca principal no fim da perspectiva do corredor.
    (limiar3d:adicionar-entidade
     (limiar3d:criar-entidade-de-malha
      malha-monolito
      :nome "monolito-central"
      :tipo :obj
      :fonte-malha (namestring arquivo-monolito)
      :posicao (limiar3d:v3 0.0 -1.0 -12.5)
      :escala (limiar3d:v3 1.6 1.6 1.6)
      :cor (limiar3d:v3 0.22 0.68 0.86)
      :fisico-p t
      :tags '(:obj :exposicao :principal)))

    ;; Cristais OBJ independentes ocupam os pedestais laterais.
    (loop for x in '(-4.2 4.2 -4.2 4.2)
          for z in '(4.0 4.0 -2.0 -2.0)
          for i from 0
          do (limiar3d:adicionar-entidade
              (limiar3d:criar-entidade-de-malha
               malha-cristal
               :nome (format nil "cristal-obj-~d" i)
               :tipo :obj
               :fonte-malha (namestring arquivo-cristal)
               :posicao (limiar3d:v3 x 0.7 z)
               :escala (limiar3d:v3 0.75 (+ 0.75 (* i 0.08)) 0.75)
               :cor (if (evenp i)
                        (limiar3d:v3 0.72 0.24 0.50)
                        (limiar3d:v3 0.32 0.72 0.62))
               :tags '(:obj :exposicao)))))

  (format t "~&[ambiente] Galeria do Monolito carregada. As obras centrais sao OBJ reais.~%"))

(limiar3d:iniciar :construtor-cena #'cena-galeria-do-monolito)
