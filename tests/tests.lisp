(defpackage #:limiar3d.tests
  (:use #:cl)
  (:export #:run-tests))

(in-package #:limiar3d.tests)

(defvar *passaram* 0)
(defvar *falharam* 0)

(defun quase= (a b &optional (epsilon 0.0001))
  (< (abs (- a b)) epsilon))

(defun vetor-quase= (v x y z &optional (epsilon 0.0001))
  (and (quase= (limiar3d::vetor3-x v) x epsilon)
       (quase= (limiar3d::vetor3-y v) y epsilon)
       (quase= (limiar3d::vetor3-z v) z epsilon)))

(defmacro testar (nome &body corpo)
  `(handler-case
       (progn
         (unless (progn ,@corpo)
           (error "resultado falso"))
         (incf *passaram*)
         (format t "[OK] ~a~%" ,nome))
     (error (erro)
       (incf *falharam*)
       (format t "[FALHA] ~a: ~a~%" ,nome erro))))

(defun run-tests ()
  (setf *passaram* 0 *falharam* 0)
  (format t "~&Limiar 3D - testes sem janela~%~%")

  (testar "soma vetorial"
    (vetor-quase= (limiar3d::v+ (limiar3d:v3 1.0 2.0 3.0)
                                 (limiar3d:v3 2.0 3.0 4.0))
                   3.0 5.0 7.0))

  (testar "normalizacao"
    (quase= 1.0
            (limiar3d::comprimento-vetor
             (limiar3d::normalizar (limiar3d:v3 3.0 4.0 0.0)))))

  (testar "camera sem rotacao olha para -Z"
    (let ((limiar3d:*camera*
            (limiar3d::make-camera
             :posicao (limiar3d:v3 0.0 0.0 0.0)
             :rotacao (limiar3d:v3 0.0 0.0 0.0))))
      (vetor-quase= (limiar3d:direcao-camera) 0.0 0.0 -1.0)))

  (testar "W usa a mesma frente da camera apos yaw"
    (let ((limiar3d:*camera*
            (limiar3d::make-camera
             :posicao (limiar3d:v3 0.0 0.0 0.0)
             :rotacao (limiar3d:v3 0.0 90.0 0.0))))
      (multiple-value-bind (frente direita)
          (limiar3d::vetores-camera-orientados)
        (declare (ignore direita))
        (let ((visual (limiar3d:direcao-camera)))
          (quase= 1.0 (limiar3d::produto-escalar frente visual) 0.0001)))))

  (testar "AABB sobreposto colide"
    (limiar3d::aabb-colidem-p
     (limiar3d::make-caixa-aabb
      :minimo (limiar3d:v3 0.0 0.0 0.0)
      :maximo (limiar3d:v3 2.0 2.0 2.0))
     (limiar3d::make-caixa-aabb
      :minimo (limiar3d:v3 1.0 1.0 1.0)
      :maximo (limiar3d:v3 3.0 3.0 3.0))))

  (testar "AABB separado nao colide"
    (not
     (limiar3d::aabb-colidem-p
      (limiar3d::make-caixa-aabb
       :minimo (limiar3d:v3 0.0 0.0 0.0)
       :maximo (limiar3d:v3 1.0 1.0 1.0))
      (limiar3d::make-caixa-aabb
       :minimo (limiar3d:v3 2.0 2.0 2.0)
       :maximo (limiar3d:v3 3.0 3.0 3.0)))))

  (testar "metadados de entidade"
    (let ((e (limiar3d:criar-cubo :nome "teste")))
      (limiar3d:definir-dado e :vida 42)
      (= 42 (limiar3d:obter-dado e :vida))))

  (testar "preparar cena vazia remove estado anterior"
    (progn
      (setf limiar3d:*entidades*
            (list (limiar3d:criar-cubo :nome "temporario"))
            limiar3d:*regras*
            (list (limiar3d:criar-regra "temporaria"
                                          (lambda () nil)
                                          (lambda () nil))))
      (limiar3d:preparar-cena-vazia)
      (and (null limiar3d:*entidades*)
           (null limiar3d:*regras*)
           (quase= -9.81
                   (limiar3d::configuracao-motor-gravidade
                    limiar3d:*configuracao*)))))

  (testar "camera inicial pertence ao ambiente"
    (progn
      (limiar3d:preparar-cena-vazia)
      (limiar3d:configurar-camera
       :posicao (limiar3d:v3 3.0 4.0 5.0)
       :rotacao (limiar3d:v3 -10.0 25.0 0.0))
      (setf (limiar3d::camera-posicao limiar3d:*camera*)
            (limiar3d:v3 99.0 99.0 99.0))
      (limiar3d::reiniciar-camera)
      (vetor-quase= (limiar3d::camera-posicao limiar3d:*camera*)
                     3.0 4.0 5.0)))

  (testar "ambiente aceita ceu fixo"
    (progn
      (limiar3d:preparar-cena-vazia)
      (limiar3d:configurar-ambiente
       :ciclo-dia-noite-p nil
       :cor-ceu (limiar3d:v3 0.1 0.2 0.3))
      (vetor-quase= (limiar3d::cor-ceu-atual) 0.1 0.2 0.3)))

  (testar "regra uma-vez"
    (let ((contador 0)
          (limiar3d:*regras* '()))
      (limiar3d:adicionar-regra
       (limiar3d:criar-regra "teste"
                             (lambda () t)
                             (lambda () (incf contador))
                             :uma-vez-p t))
      (limiar3d::atualizar-regras)
      (limiar3d::atualizar-regras)
      (= contador 1)))

  (format t "~%Resultado: ~d passaram, ~d falharam.~%"
          *passaram* *falharam*)
  (zerop *falharam*))
