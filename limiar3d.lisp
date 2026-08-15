;;;; limiar3d.lisp
;;;; ---------------------------------------------------------------------------
;;;; LIMIAR 3D v0.2.7
;;;; Um pequeno motor 3D didatico em Common Lisp, inteiro em um unico arquivo.
;;;;
;;;; Ideia central:
;;;;   O motor deve ser pequeno o bastante para uma pessoa conseguir ler o
;;;;   arquivo inteiro e entender como o mundo funciona. Ele nao tenta competir
;;;;   com Godot, Unity ou Unreal. Ele foi feito para jogos pequenos, estudos e
;;;;   experiencias em que modificar as regras do mundo pelo REPL faz parte da
;;;;   graca.
;;;;
;;;; Recursos desta versao:
;;;;   - janela OpenGL e loop de jogo;
;;;;   - delta de tempo real com limite de seguranca;
;;;;   - camera 3D em primeira pessoa;
;;;;   - entrada continua por frame, aceleracao suave e mouse-look por arrasto;
;;;;   - malhas triangulares e carregador OBJ simples;
;;;;   - cubos, piramides e chao como primitivas;
;;;;   - entidades, tags e metadados;
;;;;   - comportamentos Lisp anexados a entidades;
;;;;   - sistema de regras globais (condicao -> acao);
;;;;   - gravidade e corpos fisicos simples;
;;;;   - colisao AABB, inclusive entre objetos dinamicos;
;;;;   - raycast a partir da camera e interacao com o objeto na mira;
;;;;   - ciclo dia/noite que altera ceu e direcao da luz;
;;;;   - modo solido/aramado, grade, eixos e destaque da mira;
;;;;   - salvamento/carregamento de cenas em S-expressions legiveis;
;;;;   - alteracao ao vivo pelo REPL.
;;;;
;;;; Dependencias externas:
;;;;   - Quicklisp
;;;;   - cl-opengl
;;;;   - cl-glu
;;;;   - cl-glut
;;;;   - FreeGLUT/OpenGL instalados no sistema
;;;;
;;;; Debian/Ubuntu:
;;;;   sudo apt install sbcl freeglut3-dev libgl1-mesa-dev
;;;;
;;;; Depois de instalar Quicklisp:
;;;;   sbcl --load ~/quicklisp/setup.lisp --load limiar3d.lisp \
;;;;        --eval '(limiar3d:iniciar)'
;;;;
;;;; Controles:
;;;;   Clique + arraste esquerdo = olhar com a camera
;;;;   Clique esquerdo curto     = interagir com o objeto na mira
;;;;   W / S      = ir exatamente para onde a camera olha / voltar
;;;;   A / D      = strafe esquerdo / direito pelo eixo local da camera
;;;;   Q / E      = descer / subir (continuo)
;;;;   Shift      = movimento rapido
;;;;   Setas      = olhar (alternativa ao mouse)
;;;;   J/L e I/K  = olhar pelo teclado (alternativa)
;;;;   Clique dir = lancar um cubo fisico
;;;;   [ / ]      = diminuir / aumentar campo de visao
;;;;   C          = lancar um cubo fisico
;;;;   F          = interagir com o objeto na mira
;;;;   T          = alternar aramado / solido
;;;;   G          = mostrar / esconder grade
;;;;   O          = mostrar / esconder eixos
;;;;   N          = ligar / desligar ciclo dia/noite
;;;;   P          = pausar / continuar a simulacao
;;;;   B          = mostrar estado do motor no terminal
;;;;   R          = reconstruir a cena de demonstracao
;;;;   X          = restaurar a camera
;;;;   H          = ajuda
;;;;   ESC        = fechar
;;;;
;;;; O pipeline fixo do OpenGL e usado de proposito. Para um projeto comercial
;;;; moderno seria normal trocar esta camada por shaders, VBOs/VAOs e uma API de
;;;; janela mais moderna. Aqui, a prioridade e deixar a logica visivel.
;;;; ---------------------------------------------------------------------------

(eval-when (:compile-toplevel :load-toplevel :execute)
  ;; Quando o arquivo e carregado por ASDF, as dependencias ja devem estar
  ;; presentes. No uso standalone, tentamos Quicklisp primeiro e ASDF depois.
  (unless (and (find-package "GL")
               (find-package "GLU")
               (find-package "GLUT"))
    (cond
      ((find-package "QL")
       (funcall (symbol-function (intern "QUICKLOAD" "QL"))
                '(:cl-opengl :cl-glu :cl-glut)))
      ((find-package "ASDF")
       (dolist (sistema '(:cl-opengl :cl-glu :cl-glut))
         (funcall (symbol-function (intern "LOAD-SYSTEM" "ASDF")) sistema)))
      (t
       (error (concatenate
               'string
               "Dependencias do Limiar 3D nao encontradas. "
               "Carregue Quicklisp ou use o sistema ASDF limiar3d.asd."))))))

(defpackage #:limiar3d
  (:use #:cl)
  (:export
   ;; Entrada principal
   #:iniciar
   #:reiniciar-cena
   #:preparar-cena-vazia
   #:configurar-camera
   #:configurar-ambiente

   ;; Vetores
   #:v3

   ;; Cena e entidades
   #:adicionar-entidade
   #:remover-entidade
   #:encontrar-entidade
   #:entidades-com-tag
   #:criar-cubo
   #:criar-piramide
   #:criar-chao
   #:carregar-obj
   #:criar-entidade-de-malha
   #:lancar-cubo

   ;; Comportamentos e metadados
   #:adicionar-comportamento
   #:comportamento-flutuar
   #:comportamento-orbitar
   #:definir-dado
   #:obter-dado

   ;; Regras
   #:criar-regra
   #:adicionar-regra
   #:limpar-regras

   ;; Camera, raycast e interacao
   #:direcao-camera
   #:direita-camera
   #:entidade-na-mira
   #:interagir-com-mira

   ;; Persistencia
   #:salvar-cena
   #:carregar-cena

   ;; Estado exposto para experimentacao no REPL
   #:*entidades*
   #:*regras*
   #:*camera*
   #:*hora-do-dia*
   #:*configuracao*))

(in-package #:limiar3d)

;;; ==========================================================================
;;; 1. IDENTIDADE, CONFIGURACAO E AJUDANTES
;;; ==========================================================================

;; DEFCONSTANT exige que redefinicoes tenham valores EQL. Strings iguais
;; por conteudo nao sao necessariamente EQL, e o SBCL avalia constantes tanto
;; durante COMPILE-FILE quanto durante LOAD. Esta pequena macro conserva o
;; primeiro objeto criado quando o arquivo e compilado e carregado na mesma
;; imagem, evitando SB-EXT:DEFCONSTANT-UNEQL sem abrir mao da semantica de
;; constante. Para numeros simples, DEFCONSTANT normal continua apropriado.
(defmacro definir-constante (nome valor &optional documentacao)
  `(defconstant ,nome
     (if (boundp ',nome)
         (symbol-value ',nome)
         ,valor)
     ,@(when documentacao (list documentacao))))

(definir-constante +nome-motor+ "Limiar 3D"
  "Nome publico do motor.")
(definir-constante +versao-motor+ "0.2.7"
  "Versao publica do motor.")
(defconstant +largura-inicial+ 1100)
(defconstant +altura-inicial+ 720)
(defconstant +fps-alvo+ 60)
(defconstant +delta-padrao+ (/ 1.0 +fps-alvo+))
(defconstant +delta-maximo+ 0.05)

;; Controle da camera. As velocidades sao por segundo, portanto independem
;; da taxa de repeticao do teclado e quase independem do FPS.
(defconstant +velocidade-camera+ 6.5)
(defconstant +multiplicador-turbo+ 2.0)
(defconstant +aceleracao-camera+ 30.0)
(defconstant +freio-camera+ 38.0)
(defconstant +velocidade-rotacao-teclado+ 105.0)
(defconstant +aceleracao-rotacao-teclado+ 720.0)
(defconstant +sensibilidade-mouse+ 0.12)
(defconstant +limiar-arrasto-mouse+ 4.0)

(defconstant +distancia-interacao+ 12.0)

(defun limitar (valor minimo maximo)
  "Mantem VALOR entre MINIMO e MAXIMO."
  (max minimo (min maximo valor)))

(defun graus->radianos (graus)
  (* graus (/ pi 180.0)))

(defun quase-zero-p (valor &optional (epsilon 0.000001))
  (< (abs valor) epsilon))

(defun agora-segundos ()
  "Tempo monotonicamente crescente suficiente para calcular delta de frame."
  (/ (get-internal-real-time)
     (float internal-time-units-per-second 1.0)))

(defun ler-numero-seguro (texto)
  "Le um numero sem permitir #. ou outras formas de avaliacao pelo reader."
  (let ((*read-eval* nil))
    (multiple-value-bind (valor posicao)
        (read-from-string texto nil nil)
      (declare (ignore posicao))
      (unless (numberp valor)
        (error "Esperava um numero, recebi: ~s" texto))
      valor)))

(defstruct configuracao-motor
  (fov 60.0 :type real)
  (plano-proximo 0.05 :type real)
  (plano-distante 300.0 :type real)
  (gravidade -9.81 :type real)
  ;; Horas do mundo que passam por segundo real.
  (velocidade-dia 0.08 :type real)
  (ciclo-dia-noite-p t)
  (mostrar-grade-p t)
  (mostrar-eixos-p t)
  (mostrar-mira-p t)
  ;; NIL usa o ciclo dia/noite. Um VETOR3 fixa a cor do ceu para a cena.
  (cor-ceu-fixa nil))

(defparameter *configuracao* (make-configuracao-motor))


;;; ==========================================================================
;;; 2. MATEMATICA VETORIAL
;;; ==========================================================================

(defstruct (vetor3 (:constructor v3 (x y z)))
  (x 0.0 :type real)
  (y 0.0 :type real)
  (z 0.0 :type real))

(defun v+ (a b)
  (v3 (+ (vetor3-x a) (vetor3-x b))
      (+ (vetor3-y a) (vetor3-y b))
      (+ (vetor3-z a) (vetor3-z b))))

(defun v- (a b)
  (v3 (- (vetor3-x a) (vetor3-x b))
      (- (vetor3-y a) (vetor3-y b))
      (- (vetor3-z a) (vetor3-z b))))

(defun v* (vetor escalar)
  (v3 (* (vetor3-x vetor) escalar)
      (* (vetor3-y vetor) escalar)
      (* (vetor3-z vetor) escalar)))

(defun v-hadamard (a b)
  "Multiplicacao componente a componente. Util para aplicar escala."
  (v3 (* (vetor3-x a) (vetor3-x b))
      (* (vetor3-y a) (vetor3-y b))
      (* (vetor3-z a) (vetor3-z b))))

(defun v-min (a b)
  (v3 (min (vetor3-x a) (vetor3-x b))
      (min (vetor3-y a) (vetor3-y b))
      (min (vetor3-z a) (vetor3-z b))))

(defun v-max (a b)
  (v3 (max (vetor3-x a) (vetor3-x b))
      (max (vetor3-y a) (vetor3-y b))
      (max (vetor3-z a) (vetor3-z b))))

(defun v-lerp (a b t01)
  "Interpolacao linear entre vetores. T01 normalmente fica entre 0 e 1."
  (v+ (v* a (- 1.0 t01))
      (v* b t01)))

(defun produto-escalar (a b)
  (+ (* (vetor3-x a) (vetor3-x b))
     (* (vetor3-y a) (vetor3-y b))
     (* (vetor3-z a) (vetor3-z b))))

(defun produto-vetorial (a b)
  (v3 (- (* (vetor3-y a) (vetor3-z b))
         (* (vetor3-z a) (vetor3-y b)))
      (- (* (vetor3-z a) (vetor3-x b))
         (* (vetor3-x a) (vetor3-z b)))
      (- (* (vetor3-x a) (vetor3-y b))
         (* (vetor3-y a) (vetor3-x b)))))

(defun comprimento-vetor (v)
  (sqrt (produto-escalar v v)))

(defun distancia (a b)
  (comprimento-vetor (v- a b)))

(defun normalizar (v)
  (let ((comprimento (comprimento-vetor v)))
    (if (quase-zero-p comprimento)
        (v3 0.0 0.0 0.0)
        (v* v (/ 1.0 comprimento)))))

(defun rotacionar-vetor-x (v graus)
  (let* ((a (graus->radianos graus))
         (c (cos a))
         (s (sin a))
         (y (vetor3-y v))
         (z (vetor3-z v)))
    (v3 (vetor3-x v)
        (- (* y c) (* z s))
        (+ (* y s) (* z c)))))

(defun rotacionar-vetor-y (v graus)
  (let* ((a (graus->radianos graus))
         (c (cos a))
         (s (sin a))
         (x (vetor3-x v))
         (z (vetor3-z v)))
    (v3 (+ (* x c) (* z s))
        (vetor3-y v)
        (+ (* (- x) s) (* z c)))))

(defun rotacionar-vetor-z (v graus)
  (let* ((a (graus->radianos graus))
         (c (cos a))
         (s (sin a))
         (x (vetor3-x v))
         (y (vetor3-y v)))
    (v3 (- (* x c) (* y s))
        (+ (* x s) (* y c))
        (vetor3-z v))))

(defun rotacionar-vetor (v rotacao)
  "Aplica rotacoes Euler X, depois Y, depois Z."
  (rotacionar-vetor-z
   (rotacionar-vetor-y
    (rotacionar-vetor-x v (vetor3-x rotacao))
    (vetor3-y rotacao))
   (vetor3-z rotacao)))

(defun vetor->lista (v)
  (list (vetor3-x v) (vetor3-y v) (vetor3-z v)))

(defun lista->vetor (lista)
  (v3 (or (first lista) 0.0)
      (or (second lista) 0.0)
      (or (third lista) 0.0)))

(defun mover-vetor-ate (atual alvo mudanca-maxima)
  "Aproxima ATUAL de ALVO sem ultrapassar MUDANCA-MAXIMA.
E a versao vetorial de uma aceleracao/frenagem limitada."
  (let* ((diferenca (v- alvo atual))
         (distancia (comprimento-vetor diferenca)))
    (cond
      ((or (quase-zero-p distancia)
           (>= mudanca-maxima distancia))
       alvo)
      (t
       (v+ atual (v* diferenca (/ mudanca-maxima distancia)))))))

(defun mover-escalar-ate (atual alvo mudanca-maxima)
  "Aproxima um numero de ALVO sem ultrapassar MUDANCA-MAXIMA."
  (+ atual
     (limitar (- alvo atual)
              (- mudanca-maxima)
              mudanca-maxima)))


;;; ==========================================================================
;;; 3. TIPOS CENTRAIS DO MOTOR
;;; ==========================================================================

(defstruct transformacao
  (posicao (v3 0.0 0.0 0.0) :type vetor3)
  (rotacao (v3 0.0 0.0 0.0) :type vetor3)
  (escala   (v3 1.0 1.0 1.0) :type vetor3))

(defstruct triangulo
  (a 0 :type integer)
  (b 0 :type integer)
  (c 0 :type integer))

(defstruct malha
  (nome "malha" :type string)
  (vertices #() :type vector)
  (triangulos #() :type vector))

(defstruct caixa-aabb
  (minimo (v3 0.0 0.0 0.0) :type vetor3)
  (maximo (v3 0.0 0.0 0.0) :type vetor3))

(defstruct corpo-fisico
  ;; DINAMICO-P significa que a fisica pode mover este corpo.
  (dinamico-p nil)
  ;; SOLIDO-P significa que ele participa de colisoes.
  (solido-p t)
  (usar-gravidade-p t)
  ;; 0 = sem quique. 1 = quique idealizado.
  (restituicao 0.0 :type real)
  ;; Usado como amortecimento tangencial em contato.
  (atrito 0.12 :type real)
  (massa 1.0 :type real))

(defstruct entidade
  (id 0 :type integer)
  (nome "entidade" :type string)
  (tipo :personalizada)
  ;; Para OBJ, pode guardar o caminho do arquivo-fonte.
  (fonte-malha nil)
  (malha nil)
  (transformacao (make-transformacao) :type transformacao)
  ;; COR usa vetor3 como RGB de 0 a 1.
  (cor (v3 0.8 0.8 0.8) :type vetor3)
  (velocidade (v3 0.0 0.0 0.0) :type vetor3)
  (velocidade-rotacao (v3 0.0 0.0 0.0) :type vetor3)
  (corpo nil)
  ;; TAGS sao simbolos ou strings simples usados para consultas.
  (tags '())
  ;; DADOS e uma alist livre: (:vida . 100), (:porta . :fechada), etc.
  (dados '())
  ;; Cada comportamento e uma funcao (lambda (entidade delta) ...).
  ;; Funcoes nao sao salvas em arquivo de cena automaticamente.
  (comportamentos '())
  ;; Funcao opcional (lambda (entidade) ...), chamada ao apertar F na mira.
  (ao-interagir nil)
  (ativo-p t)
  (visivel-p t))

(defstruct camera
  (posicao (v3 0.0 2.0 9.0) :type vetor3)
  ;; X = pitch, Y = yaw, Z = roll.
  (rotacao (v3 -7.0 0.0 0.0) :type vetor3)
  ;; Velocidades mantidas na camera permitem aceleracao e frenagem suaves.
  (velocidade (v3 0.0 0.0 0.0) :type vetor3)
  (velocidade-angular (v3 0.0 0.0 0.0) :type vetor3))

(defstruct regra
  (nome "regra" :type string)
  ;; CONDICAO: (lambda () ...)
  (condicao (lambda () nil))
  ;; ACAO: (lambda () ...)
  (acao (lambda () nil))
  (uma-vez-p nil)
  (disparada-p nil)
  (ativa-p t))

(defparameter *entidades* '())
(defparameter *regras* '())
(defparameter *camera* (make-camera))
;; Cada cena pode registrar sua propria camera inicial. X volta para estes
;; valores, nao para uma posicao global fixa do motor.
(defparameter *camera-inicial-posicao* (v3 0.0 2.0 9.0))
(defparameter *camera-inicial-rotacao* (v3 -7.0 0.0 0.0))
;; R reconstrói o ambiente atualmente executado.
(defparameter *construtor-cena-atual* nil)
(defparameter *proximo-id* 1)
(defparameter *pausado-p* nil)
(defparameter *modo-aramado-p* nil)
(defparameter *hora-do-dia* 10.0)
(defparameter *tempo-mundo* 0.0)
(defparameter *entidade-em-mira* nil)

;; Temporizacao/FPS.
(defparameter *tempo-frame-anterior* nil)
(defparameter *fps-atual* 0.0)
(defparameter *frames-no-periodo* 0)
(defparameter *inicio-periodo-fps* nil)

;; Tamanho atual da area de desenho. Tambem permite reaplicar o FOV sem
;; depender de um redimensionamento manual da janela.
(defparameter *largura-janela* +largura-inicial+)
(defparameter *altura-janela* +altura-inicial+)

;; Estado de entrada. O teclado agora apenas marca teclas como pressionadas;
;; o movimento e calculado uma vez por frame em ATUALIZAR-CONTROLES-CAMERA.
(defparameter *teclas-pressionadas* (make-hash-table :test #'eql))
(defparameter *teclas-especiais-pressionadas* (make-hash-table :test #'eq))

;; O mouse so controla a camera durante um arrasto com o botao esquerdo.
;; Movimento passivo nunca altera a camera.
(defparameter *mouse-olhando-p* nil)
(defparameter *mouse-ultimo-x* 0)
(defparameter *mouse-ultimo-y* 0)
(defparameter *mouse-arrasto-acumulado* 0.0)

;; Luz direcional usada pelo sombreamento simples calculado na CPU.
(defparameter *direcao-luz* (normalizar (v3 -0.4 0.8 0.5)))


;;; ==========================================================================
;;; 4. CRIACAO DE MALHAS E PRIMITIVAS
;;; ==========================================================================

(defun criar-malha-cubo ()
  "Cubo unitario, centrado na origem."
  (make-malha
   :nome "cubo"
   :vertices
   (vector
    (v3 -0.5 -0.5 -0.5) ; 0
    (v3  0.5 -0.5 -0.5) ; 1
    (v3  0.5  0.5 -0.5) ; 2
    (v3 -0.5  0.5 -0.5) ; 3
    (v3 -0.5 -0.5  0.5) ; 4
    (v3  0.5 -0.5  0.5) ; 5
    (v3  0.5  0.5  0.5) ; 6
    (v3 -0.5  0.5  0.5)) ; 7
   :triangulos
   (vector
    (make-triangulo :a 4 :b 5 :c 6)
    (make-triangulo :a 4 :b 6 :c 7)
    (make-triangulo :a 1 :b 0 :c 3)
    (make-triangulo :a 1 :b 3 :c 2)
    (make-triangulo :a 0 :b 4 :c 7)
    (make-triangulo :a 0 :b 7 :c 3)
    (make-triangulo :a 5 :b 1 :c 2)
    (make-triangulo :a 5 :b 2 :c 6)
    (make-triangulo :a 3 :b 7 :c 6)
    (make-triangulo :a 3 :b 6 :c 2)
    (make-triangulo :a 0 :b 1 :c 5)
    (make-triangulo :a 0 :b 5 :c 4))))

(defun criar-malha-piramide ()
  "Piramide de base quadrada, altura 1, centrada aproximadamente na origem."
  (make-malha
   :nome "piramide"
   :vertices
   (vector
    (v3 -0.5 -0.5 -0.5) ; base 0
    (v3  0.5 -0.5 -0.5) ; base 1
    (v3  0.5 -0.5  0.5) ; base 2
    (v3 -0.5 -0.5  0.5) ; base 3
    (v3  0.0  0.5  0.0)) ; topo 4
   :triangulos
   (vector
    ;; Base.
    (make-triangulo :a 0 :b 2 :c 1)
    (make-triangulo :a 0 :b 3 :c 2)
    ;; Laterais.
    (make-triangulo :a 0 :b 1 :c 4)
    (make-triangulo :a 1 :b 2 :c 4)
    (make-triangulo :a 2 :b 3 :c 4)
    (make-triangulo :a 3 :b 0 :c 4))))

(defparameter *malha-cubo* (criar-malha-cubo))
(defparameter *malha-piramide* (criar-malha-piramide))

(defun criar-corpo (&key
                      (dinamico-p nil)
                      (solido-p t)
                      (usar-gravidade-p t)
                      (restituicao 0.0)
                      (atrito 0.12)
                      (massa 1.0))
  (make-corpo-fisico
   :dinamico-p dinamico-p
   :solido-p solido-p
   :usar-gravidade-p usar-gravidade-p
   :restituicao restituicao
   :atrito atrito
   :massa massa))

(defun criar-cubo (&key
                     (nome "cubo")
                     (posicao (v3 0.0 0.0 0.0))
                     (rotacao (v3 0.0 0.0 0.0))
                     (escala (v3 1.0 1.0 1.0))
                     (cor (v3 0.7 0.7 0.9))
                     (velocidade (v3 0.0 0.0 0.0))
                     (velocidade-rotacao (v3 0.0 25.0 0.0))
                     (fisico-p nil)
                     (dinamico-p nil)
                     (restituicao 0.0)
                     (atrito 0.12)
                     (tags '()))
  "Cria uma entidade com malha compartilhada de cubo."
  (make-entidade
   :nome nome
   :tipo :cubo
   :malha *malha-cubo*
   :transformacao (make-transformacao
                   :posicao posicao
                   :rotacao rotacao
                   :escala escala)
   :cor cor
   :velocidade velocidade
   :velocidade-rotacao velocidade-rotacao
   :corpo (when fisico-p
            (criar-corpo :dinamico-p dinamico-p
                         :restituicao restituicao
                         :atrito atrito))
   :tags tags))

(defun criar-piramide (&key
                         (nome "piramide")
                         (posicao (v3 0.0 0.0 0.0))
                         (rotacao (v3 0.0 0.0 0.0))
                         (escala (v3 1.0 1.0 1.0))
                         (cor (v3 0.9 0.7 0.25))
                         (velocidade (v3 0.0 0.0 0.0))
                         (velocidade-rotacao (v3 0.0 10.0 0.0))
                         (fisico-p nil)
                         (dinamico-p nil)
                         (restituicao 0.0)
                         (atrito 0.12)
                         (tags '()))
  "Cria uma piramide de base quadrada."
  (make-entidade
   :nome nome
   :tipo :piramide
   :malha *malha-piramide*
   :transformacao (make-transformacao
                   :posicao posicao
                   :rotacao rotacao
                   :escala escala)
   :cor cor
   :velocidade velocidade
   :velocidade-rotacao velocidade-rotacao
   :corpo (when fisico-p
            (criar-corpo :dinamico-p dinamico-p
                         :restituicao restituicao
                         :atrito atrito))
   :tags tags))

(defun criar-chao (&key
                     (nome "chao")
                     (y -1.25)
                     (largura 26.0)
                     (profundidade 26.0)
                     (espessura 0.5)
                     (cor (v3 0.13 0.16 0.20)))
  "Chao simples feito com um cubo grande e estatico."
  (criar-cubo
   :nome nome
   :posicao (v3 0.0 y 0.0)
   :escala (v3 largura espessura profundidade)
   :cor cor
   :velocidade-rotacao (v3 0.0 0.0 0.0)
   :fisico-p t
   :dinamico-p nil
   :tags '(:chao :cenario)))


;;; ==========================================================================
;;; 5. CARREGADOR OBJ MINIMO
;;; ==========================================================================
;;;
;;; Suporta:
;;;   v x y z
;;;   f a b c
;;;   f a/b/c b/b/b c/c/c
;;;   faces com mais de tres vertices, trianguladas em leque
;;;
;;; Nao carrega UVs, materiais ou normais do arquivo. O sombreamento calcula
;;; uma normal por triangulo. E deliberadamente pequeno e estudavel.

(defun dividir-por-espacos (texto)
  (let ((partes '())
        (inicio nil))
    (labels ((separador-p (c)
               (or (char= c #\Space) (char= c #\Tab)))
             (fechar-parte (fim)
               (when inicio
                 (push (subseq texto inicio fim) partes)
                 (setf inicio nil))))
      (loop for i from 0 below (length texto)
            for c = (char texto i)
            do (if (separador-p c)
                   (fechar-parte i)
                   (unless inicio (setf inicio i))))
      (fechar-parte (length texto)))
    (nreverse partes)))

(defun primeira-parte (texto caractere)
  (let ((posicao (position caractere texto)))
    (if posicao (subseq texto 0 posicao) texto)))

(defun indice-face-obj (texto quantidade-vertices)
  (let ((indice (parse-integer (primeira-parte texto #\/))))
    (if (plusp indice)
        (1- indice)
        (+ quantidade-vertices indice))))

(defun carregar-obj (caminho &key (nome "obj"))
  "Carrega uma MALHA OBJ. Para criar a entidade, use CRIAR-ENTIDADE-DE-MALHA."
  (let ((vertices (make-array 0 :adjustable t :fill-pointer 0))
        (triangulos (make-array 0 :adjustable t :fill-pointer 0)))
    (with-open-file (arquivo caminho :direction :input)
      (loop for linha = (read-line arquivo nil nil)
            while linha
            do (let ((partes (dividir-por-espacos linha)))
                 (when partes
                   (cond
                     ((and (string= (first partes) "v")
                           (>= (length partes) 4))
                      (vector-push-extend
                       (v3 (ler-numero-seguro (second partes))
                           (ler-numero-seguro (third partes))
                           (ler-numero-seguro (fourth partes)))
                       vertices))
                     ((and (string= (first partes) "f")
                           (>= (length partes) 4))
                      (let* ((itens (rest partes))
                             (quantidade (length vertices))
                             (indices
                               (mapcar (lambda (item)
                                         (indice-face-obj item quantidade))
                                       itens))
                             (primeiro (first indices)))
                        (loop for resto on (rest indices)
                              while (second resto)
                              do (vector-push-extend
                                  (make-triangulo
                                   :a primeiro
                                   :b (first resto)
                                   :c (second resto))
                                  triangulos))))))))
    (make-malha :nome nome
                :vertices (copy-seq vertices)
                :triangulos (copy-seq triangulos)))))

(defun criar-entidade-de-malha (malha &key
                                  (nome "objeto")
                                  (tipo :personalizada)
                                  fonte-malha
                                  (posicao (v3 0.0 0.0 0.0))
                                  (rotacao (v3 0.0 0.0 0.0))
                                  (escala (v3 1.0 1.0 1.0))
                                  (cor (v3 0.75 0.8 0.9))
                                  (fisico-p nil)
                                  (dinamico-p nil)
                                  (tags '()))
  (make-entidade
   :nome nome
   :tipo tipo
   :fonte-malha fonte-malha
   :malha malha
   :transformacao (make-transformacao
                   :posicao posicao
                   :rotacao rotacao
                   :escala escala)
   :cor cor
   :corpo (when fisico-p (criar-corpo :dinamico-p dinamico-p))
   :tags tags))


;;; ==========================================================================
;;; 6. CENA, TAGS, METADADOS E COMPORTAMENTOS
;;; ==========================================================================

(defun adicionar-entidade (entidade)
  "Adiciona ENTIDADE a cena, atribui ID se necessario e devolve a entidade."
  (when (zerop (entidade-id entidade))
    (setf (entidade-id entidade) *proximo-id*)
    (incf *proximo-id*))
  (push entidade *entidades*)
  entidade)

(defun remover-entidade (entidade)
  (setf *entidades* (remove entidade *entidades* :test #'eq))
  (when (eq *entidade-em-mira* entidade)
    (setf *entidade-em-mira* nil))
  entidade)

(defun encontrar-entidade (nome)
  "Procura pelo primeiro nome exato na cena."
  (find nome *entidades* :key #'entidade-nome :test #'string=))

(defun entidades-com-tag (tag)
  "Retorna uma nova lista com todas as entidades que possuem TAG."
  (remove-if-not
   (lambda (entidade)
     (member tag (entidade-tags entidade) :test #'equal))
   *entidades*))

(defun definir-dado (entidade chave valor)
  "Define um metadado livre em ENTIDADE e devolve VALOR."
  (let ((par (assoc chave (entidade-dados entidade) :test #'equal)))
    (if par
        (setf (cdr par) valor)
        (push (cons chave valor) (entidade-dados entidade))))
  valor)

(defun obter-dado (entidade chave &optional padrao)
  (let ((par (assoc chave (entidade-dados entidade) :test #'equal)))
    (if par (cdr par) padrao)))

(defun adicionar-comportamento (entidade funcao)
  "Anexa FUNCAO a ENTIDADE. A funcao recebe (entidade delta)."
  (push funcao (entidade-comportamentos entidade))
  entidade)

(defun comportamento-flutuar (&key (altura 0.25) (velocidade 1.5))
  "Cria uma closure que faz a entidade oscilar verticalmente sem fisica."
  (let ((fase 0.0)
        (base-y nil))
    (lambda (entidade delta)
      (unless base-y
        (setf base-y
              (vetor3-y
               (transformacao-posicao
                (entidade-transformacao entidade)))))
      (incf fase (* delta velocidade))
      (let* ((tform (entidade-transformacao entidade))
             (p (transformacao-posicao tform)))
        (setf (transformacao-posicao tform)
              (v3 (vetor3-x p)
                  (+ base-y (* altura (sin fase)))
                  (vetor3-z p)))))))

(defun comportamento-orbitar (centro raio velocidade &optional (altura 0.0))
  "Cria uma closure que orbita CENTRO no plano XZ."
  (let ((angulo 0.0))
    (lambda (entidade delta)
      (incf angulo (* velocidade delta))
      (let ((a (graus->radianos angulo)))
        (setf (transformacao-posicao
               (entidade-transformacao entidade))
              (v3 (+ (vetor3-x centro) (* raio (cos a)))
                  (+ (vetor3-y centro) altura)
                  (+ (vetor3-z centro) (* raio (sin a)))))))))


;;; ==========================================================================
;;; 7. SISTEMA DE REGRAS GLOBAIS
;;; ==========================================================================
;;;
;;; Uma regra e a forma mais simples de fazer "leis da realidade" modificaveis.
;;; Exemplo no REPL:
;;;
;;;   (limiar3d:adicionar-regra
;;;     (limiar3d:criar-regra
;;;       "anoiteceu"
;;;       (lambda () (> limiar3d:*hora-do-dia* 18.0))
;;;       (lambda () (format t "A noite chegou.~%"))
;;;       :uma-vez-p t))

(defun criar-regra (nome condicao acao &key (uma-vez-p nil))
  (make-regra :nome nome
              :condicao condicao
              :acao acao
              :uma-vez-p uma-vez-p))

(defun adicionar-regra (regra)
  (push regra *regras*)
  regra)

(defun limpar-regras ()
  (setf *regras* '()))

(defun atualizar-regras ()
  (dolist (regra (reverse *regras*))
    (when (and (regra-ativa-p regra)
               (or (not (regra-uma-vez-p regra))
                   (not (regra-disparada-p regra)))
               (funcall (regra-condicao regra)))
      (funcall (regra-acao regra))
      (setf (regra-disparada-p regra) t))))


;;; ==========================================================================
;;; 8. AABB E FISICA SIMPLES
;;; ==========================================================================

(defun transformar-ponto-local (ponto transformacao)
  "Converte um vertice da malha para posicao de mundo."
  (let* ((escalado (v-hadamard ponto (transformacao-escala transformacao)))
         (girado (rotacionar-vetor escalado
                                   (transformacao-rotacao transformacao))))
    (v+ girado (transformacao-posicao transformacao))))

(defun aabb-entidade (entidade)
  "Calcula AABB em coordenadas de mundo percorrendo os vertices transformados."
  (let ((malha (entidade-malha entidade)))
    (when (and malha (> (length (malha-vertices malha)) 0))
      (let* ((tform (entidade-transformacao entidade))
             (primeiro
               (transformar-ponto-local
                (aref (malha-vertices malha) 0)
                tform))
             (minimo primeiro)
             (maximo primeiro))
        (loop for i from 1 below (length (malha-vertices malha))
              for mundo = (transformar-ponto-local
                           (aref (malha-vertices malha) i)
                           tform)
              do (setf minimo (v-min minimo mundo)
                       maximo (v-max maximo mundo)))
        (make-caixa-aabb :minimo minimo :maximo maximo)))))

(defun centro-aabb (caixa)
  (v* (v+ (caixa-aabb-minimo caixa)
          (caixa-aabb-maximo caixa))
      0.5))

(defun aabb-colidem-p (a b)
  (and (< (vetor3-x (caixa-aabb-minimo a))
          (vetor3-x (caixa-aabb-maximo b)))
       (> (vetor3-x (caixa-aabb-maximo a))
          (vetor3-x (caixa-aabb-minimo b)))
       (< (vetor3-y (caixa-aabb-minimo a))
          (vetor3-y (caixa-aabb-maximo b)))
       (> (vetor3-y (caixa-aabb-maximo a))
          (vetor3-y (caixa-aabb-minimo b)))
       (< (vetor3-z (caixa-aabb-minimo a))
          (vetor3-z (caixa-aabb-maximo b)))
       (> (vetor3-z (caixa-aabb-maximo a))
          (vetor3-z (caixa-aabb-minimo b)))))

(defun corpo-dinamico-p (entidade)
  (let ((corpo (entidade-corpo entidade)))
    (and corpo
         (corpo-fisico-solido-p corpo)
         (corpo-fisico-dinamico-p corpo))))

(defun corpo-solido-p (entidade)
  (let ((corpo (entidade-corpo entidade)))
    (and corpo (corpo-fisico-solido-p corpo))))

(defun mover-entidade-eixo (entidade eixo quantidade)
  (let* ((tform (entidade-transformacao entidade))
         (p (transformacao-posicao tform)))
    (setf (transformacao-posicao tform)
          (ecase eixo
            (:x (v3 (+ (vetor3-x p) quantidade)
                    (vetor3-y p)
                    (vetor3-z p)))
            (:y (v3 (vetor3-x p)
                    (+ (vetor3-y p) quantidade)
                    (vetor3-z p)))
            (:z (v3 (vetor3-x p)
                    (vetor3-y p)
                    (+ (vetor3-z p) quantidade)))))))

(defun componente-vetor (v eixo)
  (ecase eixo
    (:x (vetor3-x v))
    (:y (vetor3-y v))
    (:z (vetor3-z v))))

(defun definir-componente-vetor (v eixo valor)
  (ecase eixo
    (:x (v3 valor (vetor3-y v) (vetor3-z v)))
    (:y (v3 (vetor3-x v) valor (vetor3-z v)))
    (:z (v3 (vetor3-x v) (vetor3-y v) valor))))

(defun amortecer-tangencial (entidade eixo atrito)
  "Reduz movimento nos eixos tangentes a uma colisao."
  (let* ((v (entidade-velocidade entidade))
         (fator (limitar (- 1.0 atrito) 0.0 1.0)))
    (setf (entidade-velocidade entidade)
          (ecase eixo
            (:x (v3 (vetor3-x v)
                    (* (vetor3-y v) fator)
                    (* (vetor3-z v) fator)))
            (:y (v3 (* (vetor3-x v) fator)
                    (vetor3-y v)
                    (* (vetor3-z v) fator)))
            (:z (v3 (* (vetor3-x v) fator)
                    (* (vetor3-y v) fator)
                    (vetor3-z v)))))))

(defun resolver-velocidade-colisao (entidade eixo normal restitucao atrito)
  "Remove a componente entrando na superficie e aplica um quique simples."
  (let* ((v (entidade-velocidade entidade))
         (componente (componente-vetor v eixo)))
    ;; NORMAL aponta para fora da outra caixa. Se componente*normal < 0,
    ;; a entidade ainda se move contra a superficie.
    (when (< (* componente normal) 0.0)
      (let ((novo (* (- componente) restitucao)))
        (when (< (abs novo) 0.05)
          (setf novo 0.0))
        (setf (entidade-velocidade entidade)
              (definir-componente-vetor v eixo novo))))
    (amortecer-tangencial entidade eixo atrito)))

(defun resolver-colisao-par (a b)
  "Resolve uma sobreposicao AABB escolhendo o eixo de menor penetracao."
  (let ((ca (aabb-entidade a))
        (cb (aabb-entidade b)))
    (when (and ca cb (aabb-colidem-p ca cb))
      (let* ((mina (caixa-aabb-minimo ca))
             (maxa (caixa-aabb-maximo ca))
             (minb (caixa-aabb-minimo cb))
             (maxb (caixa-aabb-maximo cb))
             (px (- (min (vetor3-x maxa) (vetor3-x maxb))
                    (max (vetor3-x mina) (vetor3-x minb))))
             (py (- (min (vetor3-y maxa) (vetor3-y maxb))
                    (max (vetor3-y mina) (vetor3-y minb))))
             (pz (- (min (vetor3-z maxa) (vetor3-z maxb))
                    (max (vetor3-z mina) (vetor3-z minb))))
             (eixo (cond ((and (<= px py) (<= px pz)) :x)
                         ((<= py pz) :y)
                         (t :z)))
             (penetracao (ecase eixo (:x px) (:y py) (:z pz)))
             (centro-a (centro-aabb ca))
             (centro-b (centro-aabb cb))
             ;; NORMAL-A aponta de B para A no eixo escolhido.
             (normal-a (if (< (componente-vetor centro-a eixo)
                              (componente-vetor centro-b eixo))
                           -1.0
                           1.0))
             (din-a (corpo-dinamico-p a))
             (din-b (corpo-dinamico-p b)))
        (when (or din-a din-b)
          (cond
            ((and din-a din-b)
             (mover-entidade-eixo a eixo (* normal-a penetracao 0.5))
             (mover-entidade-eixo b eixo (* (- normal-a) penetracao 0.5)))
            (din-a
             (mover-entidade-eixo a eixo (* normal-a penetracao)))
            (din-b
             (mover-entidade-eixo b eixo (* (- normal-a) penetracao))))

          (when din-a
            (let* ((corpo-a (entidade-corpo a))
                   (corpo-b (entidade-corpo b))
                   (rest (if corpo-b
                             (/ (+ (corpo-fisico-restituicao corpo-a)
                                   (corpo-fisico-restituicao corpo-b))
                                2.0)
                             (corpo-fisico-restituicao corpo-a)))
                   (atrito (corpo-fisico-atrito corpo-a)))
              (resolver-velocidade-colisao a eixo normal-a rest atrito)))

          (when din-b
            (let* ((corpo-b (entidade-corpo b))
                   (corpo-a (entidade-corpo a))
                   (rest (if corpo-a
                             (/ (+ (corpo-fisico-restituicao corpo-b)
                                   (corpo-fisico-restituicao corpo-a))
                                2.0)
                             (corpo-fisico-restituicao corpo-b)))
                   (atrito (corpo-fisico-atrito corpo-b)))
              (resolver-velocidade-colisao b eixo (- normal-a) rest atrito))))))))

(defun atualizar-fisica-entidade (entidade delta)
  (let ((corpo (entidade-corpo entidade)))
    (when (and corpo (corpo-fisico-dinamico-p corpo))
      (when (corpo-fisico-usar-gravidade-p corpo)
        (incf (vetor3-y (entidade-velocidade entidade))
              (* (configuracao-motor-gravidade *configuracao*) delta)))))

  ;; Velocidade linear funciona para qualquer entidade, com ou sem corpo.
  (let* ((tform (entidade-transformacao entidade))
         (posicao (transformacao-posicao tform)))
    (setf (transformacao-posicao tform)
          (v+ posicao (v* (entidade-velocidade entidade) delta))))

  ;; Rotacao automatica.
  (let* ((tform (entidade-transformacao entidade))
         (rotacao (transformacao-rotacao tform)))
    (setf (transformacao-rotacao tform)
          (v+ rotacao (v* (entidade-velocidade-rotacao entidade) delta)))))

(defun resolver-colisoes ()
  "Testa cada par uma vez. Adequado para cenas pequenas e didaticas."
  (loop for resto on *entidades*
        for a = (first resto)
        when (and a (entidade-ativo-p a) (corpo-solido-p a))
          do (dolist (b (rest resto))
               (when (and (entidade-ativo-p b)
                          (corpo-solido-p b)
                          (or (corpo-dinamico-p a)
                              (corpo-dinamico-p b)))
                 (resolver-colisao-par a b)))))


;;; ==========================================================================
;;; 9. CAMERA, RAYCAST E INTERACAO
;;; ==========================================================================

(defun reiniciar-camera ()
  "Volta para a camera inicial registrada pela cena atual."
  (setf *camera*
        (make-camera
         :posicao *camera-inicial-posicao*
         :rotacao *camera-inicial-rotacao*)))

(defun tecla-ativa-p (tecla)
  "Verdadeiro enquanto TECLA comum estiver fisicamente pressionada."
  (gethash (char-downcase tecla) *teclas-pressionadas*))

(defun tecla-especial-ativa-p (tecla)
  (gethash tecla *teclas-especiais-pressionadas*))

(defun eixo-entrada (positivo negativo)
  "Retorna -1, 0 ou 1 para um par de teclas opostas."
  (- (if positivo 1.0 0.0)
     (if negativo 1.0 0.0)))

(defun vetor-local-camera->mundo (vetor)
  "Converte VETOR do espaco local da camera para o espaco do mundo.

Esta funcao e a fonte unica de verdade para orientacao da camera. Ela usa a
inversa EXATA da mesma ordem de rotacoes usada por APLICAR-CAMERA.

APLICAR-CAMERA monta a visao como:
  Rz(-roll) * Rx(-pitch) * Ry(-yaw) * T(-posicao)

Logo, para transformar um vetor local da camera de volta para o mundo usamos:
  Ry(yaw) * Rx(pitch) * Rz(roll)

Como matrizes agem da direita para a esquerda, o vetor e rotacionado primeiro
em Z, depois em X e por ultimo em Y. Isso garante que o centro da tela, o
raycast e W usem exatamente a mesma direcao geometrica."
  (let ((r (camera-rotacao *camera*)))
    (rotacionar-vetor-y
     (rotacionar-vetor-x
      (rotacionar-vetor-z vetor (vetor3-z r))
      (vetor3-x r))
     (vetor3-y r))))

(defun direcao-camera ()
  "Vetor unitario que sai da camera pelo centro da tela.
E tambem, deliberadamente, a direcao usada por W."
  (normalizar
   (vetor-local-camera->mundo (v3 0.0 0.0 -1.0))))

(defun direita-camera ()
  "Vetor unitario para a direita da camera, usado pelo strafe A/D."
  (normalizar
   (vetor-local-camera->mundo (v3 1.0 0.0 0.0))))

(defun vetores-camera-orientados ()
  "Retorna FRENTE e DIREITA calculados pela transformacao real da camera.

FRENTE e exatamente DIRECAO-CAMERA. Portanto, se algo esta no centro da tela,
segurar W desloca a camera na direcao daquele ponto. A/D usam o eixo X local
da propria camera, inclusive se futuramente houver roll."
  (values (direcao-camera)
          (direita-camera)))

(defun mover-camera-horizontal (frente direita)
  "Move imediatamente em FRENTE/DIREITA relativos a camera.
Mantido como utilitario para o REPL apesar do nome historico."
  (multiple-value-bind (vetor-frente vetor-direita)
      (vetores-camera-orientados)
    (setf (camera-posicao *camera*)
          (v+ (camera-posicao *camera*)
              (v+ (v* vetor-frente frente)
                  (v* vetor-direita direita))))))

(defun mover-camera-vertical (quantidade)
  "Move imediatamente no eixo Y. Mantido como utilitario para o REPL."
  (let ((p (camera-posicao *camera*)))
    (setf (camera-posicao *camera*)
          (v3 (vetor3-x p)
              (+ (vetor3-y p) quantidade)
              (vetor3-z p)))))

(defun girar-camera (pitch yaw)
  "Aplica uma variacao angular imediata em graus."
  (let ((r (camera-rotacao *camera*)))
    (setf (camera-rotacao *camera*)
          (v3 (limitar (+ (vetor3-x r) pitch) -89.0 89.0)
              (+ (vetor3-y r) yaw)
              (vetor3-z r)))))

(defun entrada-turbo-p ()
  "Shift esquerdo/direito acelera quando o FreeGLUT envia essas teclas."
  (or (tecla-especial-ativa-p :key-left-shift)
      (tecla-especial-ativa-p :key-right-shift)
      (tecla-especial-ativa-p :key-shift-l)
      (tecla-especial-ativa-p :key-shift-r)))

(defun atualizar-movimento-camera (delta)
  "Converte WASDQE em movimento suave relativo a transformacao da camera.
W/S usam exatamente DIRECAO-CAMERA; A/D usam o eixo lateral local da camera;
Q/E continuam usando o eixo Y global como controle vertical independente."
  (let* ((frente (eixo-entrada (tecla-ativa-p #\w)
                               (tecla-ativa-p #\s)))
         (direita (eixo-entrada (tecla-ativa-p #\d)
                                (tecla-ativa-p #\a)))
         (vertical (eixo-entrada (tecla-ativa-p #\e)
                                 (tecla-ativa-p #\q)))
         (ha-entrada (or (not (zerop frente))
                         (not (zerop direita))
                         (not (zerop vertical))))
         (velocidade-maxima
           (* +velocidade-camera+
              (if (entrada-turbo-p) +multiplicador-turbo+ 1.0))))
    (multiple-value-bind (vetor-frente vetor-direita)
        (vetores-camera-orientados)
      (let ((direcao
              (v+ (v+ (v* vetor-frente frente)
                      (v* vetor-direita direita))
                  (v3 0.0 vertical 0.0))))
        (if ha-entrada
            ;; IMPORTANTE: suavizamos apenas o MODULO da velocidade.
            ;; A direcao e aplicada imediatamente a partir da camera atual.
            ;; Assim, virar a camera enquanto segura W nao deixa inercia
            ;; lateral apontando para a orientacao antiga.
            (let* ((direcao-unitaria (normalizar direcao))
                   (velocidade-atual
                     (comprimento-vetor (camera-velocidade *camera*)))
                   (nova-velocidade
                     (mover-escalar-ate velocidade-atual
                                       velocidade-maxima
                                       (* +aceleracao-camera+ delta))))
              (setf (camera-velocidade *camera*)
                    (v* direcao-unitaria nova-velocidade)))
            ;; Sem entrada, preservamos apenas uma pequena desaceleracao suave.
            (setf (camera-velocidade *camera*)
                  (mover-vetor-ate (camera-velocidade *camera*)
                                   (v3 0.0 0.0 0.0)
                                   (* +freio-camera+ delta))))

        (setf (camera-posicao *camera*)
              (v+ (camera-posicao *camera*)
                  (v* (camera-velocidade *camera*) delta)))))))

(defun atualizar-rotacao-teclado (delta)
  "Setas ou IJKL produzem rotacao continua com aceleracao e desaceleracao."
  (let* ((olhar-direita
           (or (tecla-ativa-p #\l)
               (tecla-especial-ativa-p :key-right)))
         (olhar-esquerda
           (or (tecla-ativa-p #\j)
               (tecla-especial-ativa-p :key-left)))
         (olhar-baixo
           (or (tecla-ativa-p #\k)
               (tecla-especial-ativa-p :key-down)))
         (olhar-cima
           (or (tecla-ativa-p #\i)
               (tecla-especial-ativa-p :key-up)))
         ;; Pitch negativo olha para cima neste sistema de coordenadas.
         (pitch (* (eixo-entrada olhar-baixo olhar-cima)
                   +velocidade-rotacao-teclado+))
         (yaw (* (eixo-entrada olhar-direita olhar-esquerda)
                 +velocidade-rotacao-teclado+))
         (alvo (v3 pitch yaw 0.0)))
    (setf (camera-velocidade-angular *camera*)
          (mover-vetor-ate (camera-velocidade-angular *camera*)
                           alvo
                           (* +aceleracao-rotacao-teclado+ delta)))
    (let ((v (camera-velocidade-angular *camera*)))
      (girar-camera (* (vetor3-x v) delta)
                    (* (vetor3-y v) delta)))))

(defun atualizar-controles-camera (delta)
  "Atualiza os controles continuos uma vez por frame."
  (atualizar-movimento-camera delta)
  (atualizar-rotacao-teclado delta))

(defun iniciar-arrasto-camera (x y)
  "Comeca um gesto de olhar com o botao esquerdo pressionado."
  (setf *mouse-olhando-p* t
        *mouse-ultimo-x* x
        *mouse-ultimo-y* y
        *mouse-arrasto-acumulado* 0.0))

(defun atualizar-arrasto-camera (x y)
  "Gira a camera apenas enquanto o usuario esta arrastando o mouse."
  (when *mouse-olhando-p*
    (let ((dx (- x *mouse-ultimo-x*))
          (dy (- y *mouse-ultimo-y*)))
      (incf *mouse-arrasto-acumulado*
            (sqrt (+ (* dx dx) (* dy dy))))
      (setf *mouse-ultimo-x* x
            *mouse-ultimo-y* y)
      (unless (and (zerop dx) (zerop dy))
        (girar-camera (* dy +sensibilidade-mouse+)
                      (* dx +sensibilidade-mouse+))))))

(defun finalizar-arrasto-camera ()
  "Termina o arrasto e informa se ele foi curto o bastante para ser um clique."
  (let ((foi-clique-p (< *mouse-arrasto-acumulado* +limiar-arrasto-mouse+)))
    (setf *mouse-olhando-p* nil)
    foi-clique-p))

(defun aplicar-camera ()
  (let ((p (camera-posicao *camera*))
        (r (camera-rotacao *camera*)))
    (gl:rotate (- (vetor3-z r)) 0.0 0.0 1.0)
    (gl:rotate (- (vetor3-x r)) 1.0 0.0 0.0)
    (gl:rotate (- (vetor3-y r)) 0.0 1.0 0.0)
    (gl:translate (- (vetor3-x p))
                  (- (vetor3-y p))
                  (- (vetor3-z p)))))

(defun intervalo-raio-eixo (origem direcao minimo maximo)
  "Retorna TMIN e TMAX do raio nesse eixo; NIL quando impossivel."
  (if (quase-zero-p direcao)
      (if (or (< origem minimo) (> origem maximo))
          (values nil nil)
          (values -1.0e30 1.0e30))
      (let* ((t1 (/ (- minimo origem) direcao))
             (t2 (/ (- maximo origem) direcao)))
        (values (min t1 t2) (max t1 t2)))))

(defun distancia-raio-aabb (origem direcao caixa)
  "Distancia ate CAIXA ou NIL se o raio nao atinge a caixa."
  (let ((tmin -1.0e30)
        (tmax 1.0e30))
    (labels ((testar (o d mn mx)
               (multiple-value-bind (a b)
                   (intervalo-raio-eixo o d mn mx)
                 (when (null a)
                   (return-from distancia-raio-aabb nil))
                 (setf tmin (max tmin a)
                       tmax (min tmax b))
                 (when (> tmin tmax)
                   (return-from distancia-raio-aabb nil)))))
      (testar (vetor3-x origem) (vetor3-x direcao)
              (vetor3-x (caixa-aabb-minimo caixa))
              (vetor3-x (caixa-aabb-maximo caixa)))
      (testar (vetor3-y origem) (vetor3-y direcao)
              (vetor3-y (caixa-aabb-minimo caixa))
              (vetor3-y (caixa-aabb-maximo caixa)))
      (testar (vetor3-z origem) (vetor3-z direcao)
              (vetor3-z (caixa-aabb-minimo caixa))
              (vetor3-z (caixa-aabb-maximo caixa))))
    (cond
      ((>= tmin 0.0) tmin)
      ((>= tmax 0.0) 0.0)
      (t nil))))

(defun entidade-na-mira (&optional (distancia-maxima +distancia-interacao+))
  "Retorna ENTIDADE e DISTANCIA do primeiro AABB atingido pela camera."
  (let ((origem (camera-posicao *camera*))
        (direcao (direcao-camera))
        (melhor nil)
        (melhor-distancia distancia-maxima))
    (dolist (entidade *entidades*)
      (when (and (entidade-ativo-p entidade)
                 (entidade-visivel-p entidade)
                 (entidade-malha entidade))
        (let ((caixa (aabb-entidade entidade)))
          (when caixa
            (let ((d (distancia-raio-aabb origem direcao caixa)))
              (when (and d (> d 0.05) (< d melhor-distancia))
                (setf melhor entidade
                      melhor-distancia d)))))))
    (values melhor (and melhor melhor-distancia))))

(defun atualizar-mira ()
  (setf *entidade-em-mira* (entidade-na-mira)))

(defun interagir-com-mira ()
  "Executa AO-INTERAGIR ou apenas informa qual entidade esta na mira."
  (multiple-value-bind (entidade d)
      (entidade-na-mira)
    (if entidade
        (progn
          (format t "~&[interacao] ~a (id ~d), distancia ~,2f~%"
                  (entidade-nome entidade)
                  (entidade-id entidade)
                  d)
          (if (entidade-ao-interagir entidade)
              (funcall (entidade-ao-interagir entidade) entidade)
              (format t "  Esta entidade nao possui :ao-interagir.~%")))
        (format t "~&[interacao] Nada ao alcance.~%"))))

(defun lancar-cubo (&key (forca 8.0))
  "Cria um cubo fisico diante da camera e o arremessa para frente."
  (let* ((direcao (direcao-camera))
         (origem (camera-posicao *camera*))
         (posicao (v+ origem (v* direcao 2.0)))
         (nome (format nil "cubo-lancado-~d" *proximo-id*)))
    (adicionar-entidade
     (criar-cubo
      :nome nome
      :posicao posicao
      :escala (v3 0.55 0.55 0.55)
      :cor (v3 0.95 0.55 0.18)
      :velocidade (v* direcao forca)
      :velocidade-rotacao (v3 80.0 130.0 45.0)
      :fisico-p t
      :dinamico-p t
      :restituicao 0.18
      :atrito 0.18
      :tags '(:lancavel :fisica)))))


;;; ==========================================================================
;;; 10. CICLO DIA/NOITE
;;; ==========================================================================

(defun atualizar-ciclo-dia-noite (delta)
  (when (configuracao-motor-ciclo-dia-noite-p *configuracao*)
    (setf *hora-do-dia*
          (mod (+ *hora-do-dia*
                  (* delta
                     (configuracao-motor-velocidade-dia *configuracao*)))
               24.0)))

  ;; O angulo coloca o sol alto aproximadamente ao meio-dia.
  (let* ((angulo (graus->radianos
                  (- (* (/ *hora-do-dia* 24.0) 360.0) 90.0)))
         (altura (sin angulo)))
    ;; Durante a noite usamos uma direcao oposta mais fraca visualmente;
    ;; a intensidade final continua limitada pela luz ambiente no shader CPU.
    (setf *direcao-luz*
          (normalizar
           (v3 0.35
               (if (> altura 0.0) altura (- (* 0.35 altura)))
               (cos angulo))))))

(defun fator-dia ()
  "0 = noite profunda, 1 = dia claro."
  (let* ((angulo (graus->radianos
                  (- (* (/ *hora-do-dia* 24.0) 360.0) 90.0)))
         (altura (sin angulo)))
    (limitar (+ 0.12 (* 1.25 (max 0.0 altura))) 0.0 1.0)))

(defun cor-ceu-atual ()
  (or (configuracao-motor-cor-ceu-fixa *configuracao*)
      (v-lerp (v3 0.018 0.025 0.055)
              (v3 0.22 0.42 0.68)
              (fator-dia))))


;;; ==========================================================================
;;; 11. ATUALIZACAO DA SIMULACAO
;;; ==========================================================================

(defun atualizar-comportamentos (entidade delta)
  (dolist (comportamento (reverse (entidade-comportamentos entidade)))
    (funcall comportamento entidade delta)))

(defun atualizar-mundo (delta)
  ;; A camera continua responsiva mesmo quando a simulacao esta pausada.
  (atualizar-controles-camera delta)

  (unless *pausado-p*
    (incf *tempo-mundo* delta)
    (atualizar-ciclo-dia-noite delta)

    (dolist (entidade *entidades*)
      (when (entidade-ativo-p entidade)
        (atualizar-comportamentos entidade delta)
        (atualizar-fisica-entidade entidade delta)))

    (resolver-colisoes)
    (atualizar-regras))

  ;; A mira continua atualizando mesmo pausado.
  (atualizar-mira))

(defun calcular-delta-frame ()
  (let ((agora (agora-segundos)))
    (prog1
        (if *tempo-frame-anterior*
            (limitar (- agora *tempo-frame-anterior*) 0.0 +delta-maximo+)
            +delta-padrao+)
      (setf *tempo-frame-anterior* agora))))

(defun atualizar-fps ()
  (let ((agora (agora-segundos)))
    (unless *inicio-periodo-fps*
      (setf *inicio-periodo-fps* agora))
    (incf *frames-no-periodo*)
    (let ((duracao (- agora *inicio-periodo-fps*)))
      (when (>= duracao 1.0)
        (setf *fps-atual* (/ *frames-no-periodo* duracao)
              *frames-no-periodo* 0
              *inicio-periodo-fps* agora)))))


;;; ==========================================================================
;;; 12. RENDERIZACAO
;;; ==========================================================================

(defun enviar-vertice-opengl (v)
  (gl:vertex (vetor3-x v) (vetor3-y v) (vetor3-z v)))

(defun cor-sombreada (cor intensidade)
  (v3 (limitar (* (vetor3-x cor) intensidade) 0.0 1.0)
      (limitar (* (vetor3-y cor) intensidade) 0.0 1.0)
      (limitar (* (vetor3-z cor) intensidade) 0.0 1.0)))

(defun normal-local-triangulo (malha triangulo)
  (let* ((vertices (malha-vertices malha))
         (a (aref vertices (triangulo-a triangulo)))
         (b (aref vertices (triangulo-b triangulo)))
         (c (aref vertices (triangulo-c triangulo))))
    (normalizar (produto-vetorial (v- b a) (v- c a)))))

(defun intensidade-luz (malha triangulo rotacao)
  (let* ((normal-local (normal-local-triangulo malha triangulo))
         (normal-mundo (normalizar (rotacionar-vetor normal-local rotacao)))
         (difusa (max 0.0 (produto-escalar normal-mundo *direcao-luz*)))
         ;; Noite recebe ambiente menor.
         (ambiente (+ 0.12 (* 0.14 (fator-dia)))))
    (+ ambiente (* (- 1.0 ambiente) difusa))))

(defun desenhar-malha (malha cor rotacao)
  (let ((vertices (malha-vertices malha)))
    (gl:begin :triangles)
    (loop for triangulo across (malha-triangulos malha)
          do (let* ((luz (intensidade-luz malha triangulo rotacao))
                    (cor-final (cor-sombreada cor luz)))
               (gl:color (vetor3-x cor-final)
                         (vetor3-y cor-final)
                         (vetor3-z cor-final))
               (enviar-vertice-opengl
                (aref vertices (triangulo-a triangulo)))
               (enviar-vertice-opengl
                (aref vertices (triangulo-b triangulo)))
               (enviar-vertice-opengl
                (aref vertices (triangulo-c triangulo)))))
    (gl:end)))

(defun desenhar-entidade (entidade)
  (when (and (entidade-ativo-p entidade)
             (entidade-visivel-p entidade)
             (entidade-malha entidade))
    (let* ((tform (entidade-transformacao entidade))
           (p (transformacao-posicao tform))
           (r (transformacao-rotacao tform))
           (s (transformacao-escala tform)))
      (gl:push-matrix)
      (unwind-protect
           (progn
             (gl:translate (vetor3-x p) (vetor3-y p) (vetor3-z p))
             (gl:rotate (vetor3-x r) 1.0 0.0 0.0)
             (gl:rotate (vetor3-y r) 0.0 1.0 0.0)
             (gl:rotate (vetor3-z r) 0.0 0.0 1.0)
             (gl:scale (vetor3-x s) (vetor3-y s) (vetor3-z s))
             (desenhar-malha (entidade-malha entidade)
                             (entidade-cor entidade)
                             r))
        (gl:pop-matrix)))))

(defun desenhar-grade (&key (tamanho 13) (passo 1))
  "Grade no plano XZ, em Y=-1.0, ligeiramente acima do chao demo."
  (gl:color 0.24 0.27 0.31)
  (gl:begin :lines)
  (loop for i from (- tamanho) to tamanho by passo
        do (progn
             (gl:vertex i -0.995 (- tamanho))
             (gl:vertex i -0.995 tamanho)
             (gl:vertex (- tamanho) -0.995 i)
             (gl:vertex tamanho -0.995 i)))
  (gl:end))

(defun desenhar-eixos (&optional (tamanho 2.0))
  (gl:begin :lines)
  (gl:color 1.0 0.2 0.2)
  (gl:vertex 0.0 0.0 0.0)
  (gl:vertex tamanho 0.0 0.0)
  (gl:color 0.2 1.0 0.2)
  (gl:vertex 0.0 0.0 0.0)
  (gl:vertex 0.0 tamanho 0.0)
  (gl:color 0.2 0.45 1.0)
  (gl:vertex 0.0 0.0 0.0)
  (gl:vertex 0.0 0.0 tamanho)
  (gl:end))

(defun desenhar-caixa-aabb (caixa)
  "Desenha as 12 arestas de uma AABB."
  (let* ((mn (caixa-aabb-minimo caixa))
         (mx (caixa-aabb-maximo caixa))
         (x0 (vetor3-x mn)) (y0 (vetor3-y mn)) (z0 (vetor3-z mn))
         (x1 (vetor3-x mx)) (y1 (vetor3-y mx)) (z1 (vetor3-z mx)))
    (gl:begin :lines)
    ;; Face inferior.
    (gl:vertex x0 y0 z0) (gl:vertex x1 y0 z0)
    (gl:vertex x1 y0 z0) (gl:vertex x1 y0 z1)
    (gl:vertex x1 y0 z1) (gl:vertex x0 y0 z1)
    (gl:vertex x0 y0 z1) (gl:vertex x0 y0 z0)
    ;; Face superior.
    (gl:vertex x0 y1 z0) (gl:vertex x1 y1 z0)
    (gl:vertex x1 y1 z0) (gl:vertex x1 y1 z1)
    (gl:vertex x1 y1 z1) (gl:vertex x0 y1 z1)
    (gl:vertex x0 y1 z1) (gl:vertex x0 y1 z0)
    ;; Verticais.
    (gl:vertex x0 y0 z0) (gl:vertex x0 y1 z0)
    (gl:vertex x1 y0 z0) (gl:vertex x1 y1 z0)
    (gl:vertex x1 y0 z1) (gl:vertex x1 y1 z1)
    (gl:vertex x0 y0 z1) (gl:vertex x0 y1 z1)
    (gl:end)))

(defun desenhar-destaque-mira ()
  (when (and (configuracao-motor-mostrar-mira-p *configuracao*)
             *entidade-em-mira*)
    (let ((caixa (aabb-entidade *entidade-em-mira*)))
      (when caixa
        (gl:line-width 2.0)
        (gl:color 1.0 0.92 0.25)
        (desenhar-caixa-aabb caixa)
        (gl:line-width 1.0)))))

(defun aplicar-cor-ceu ()
  (let ((ceu (cor-ceu-atual)))
    (gl:clear-color (vetor3-x ceu)
                    (vetor3-y ceu)
                    (vetor3-z ceu)
                    1.0)))

(defun renderizar-mundo ()
  (aplicar-cor-ceu)
  (gl:clear :color-buffer-bit :depth-buffer-bit)
  (gl:matrix-mode :modelview)
  (gl:load-identity)
  (aplicar-camera)

  (gl:polygon-mode :front-and-back
                   (if *modo-aramado-p* :line :fill))

  (when (configuracao-motor-mostrar-grade-p *configuracao*)
    (desenhar-grade))
  (when (configuracao-motor-mostrar-eixos-p *configuracao*)
    (desenhar-eixos))

  (dolist (entidade (reverse *entidades*))
    (desenhar-entidade entidade))

  ;; A caixa de mira e sempre linha, mesmo se o resto estiver solido.
  (let ((modo-anterior *modo-aramado-p*))
    (declare (ignore modo-anterior))
    (gl:polygon-mode :front-and-back :line)
    (desenhar-destaque-mira)
    (gl:polygon-mode :front-and-back
                     (if *modo-aramado-p* :line :fill)))

  (glut:swap-buffers))


;;; ==========================================================================
;;; 13. SALVAMENTO E CARREGAMENTO DE CENA
;;; ==========================================================================
;;;
;;; O formato e uma S-expression normal. Isso e intencional: voce pode abrir
;;; o arquivo salvo num editor de texto, ler e ate alterar os valores a mao.
;;; Closures de comportamentos, regras e callbacks de interacao nao sao
;;; serializadas porque uma funcao compilada nao possui representacao portavel
;;; e legivel por READ.

(defun corpo->dados (corpo)
  (when corpo
    (list :dinamico-p (corpo-fisico-dinamico-p corpo)
          :solido-p (corpo-fisico-solido-p corpo)
          :usar-gravidade-p (corpo-fisico-usar-gravidade-p corpo)
          :restituicao (corpo-fisico-restituicao corpo)
          :atrito (corpo-fisico-atrito corpo)
          :massa (corpo-fisico-massa corpo))))

(defun entidade->dados-salvaveis (entidade)
  (let ((tform (entidade-transformacao entidade)))
    (list
     :nome (entidade-nome entidade)
     :tipo (entidade-tipo entidade)
     :fonte-malha (entidade-fonte-malha entidade)
     :posicao (vetor->lista (transformacao-posicao tform))
     :rotacao (vetor->lista (transformacao-rotacao tform))
     :escala (vetor->lista (transformacao-escala tform))
     :cor (vetor->lista (entidade-cor entidade))
     :velocidade (vetor->lista (entidade-velocidade entidade))
     :velocidade-rotacao (vetor->lista (entidade-velocidade-rotacao entidade))
     :corpo (corpo->dados (entidade-corpo entidade))
     :tags (copy-list (entidade-tags entidade))
     :ativo-p (entidade-ativo-p entidade)
     :visivel-p (entidade-visivel-p entidade))))

(defun configuracao->dados ()
  (list
   :fov (configuracao-motor-fov *configuracao*)
   :plano-proximo (configuracao-motor-plano-proximo *configuracao*)
   :plano-distante (configuracao-motor-plano-distante *configuracao*)
   :gravidade (configuracao-motor-gravidade *configuracao*)
   :velocidade-dia (configuracao-motor-velocidade-dia *configuracao*)
   :ciclo-dia-noite-p
   (configuracao-motor-ciclo-dia-noite-p *configuracao*)
   :mostrar-grade-p
   (configuracao-motor-mostrar-grade-p *configuracao*)
   :mostrar-eixos-p
   (configuracao-motor-mostrar-eixos-p *configuracao*)
   :mostrar-mira-p
   (configuracao-motor-mostrar-mira-p *configuracao*)
   :cor-ceu-fixa
   (let ((cor (configuracao-motor-cor-ceu-fixa *configuracao*)))
     (and cor (vetor->lista cor)))))

(defun salvar-cena (caminho)
  "Salva a cena em uma S-expression humana e devolve CAMINHO."
  (let ((dados
          (list
           :formato :limiar3d-cena
           :versao 1
           :hora-do-dia *hora-do-dia*
           :tempo-mundo *tempo-mundo*
           :configuracao (configuracao->dados)
           :camera
           (list :posicao (vetor->lista (camera-posicao *camera*))
                 :rotacao (vetor->lista (camera-rotacao *camera*)))
           :entidades
           (mapcar #'entidade->dados-salvaveis
                   (reverse *entidades*)))))
    (with-open-file (arquivo caminho
                             :direction :output
                             :if-exists :supersede
                             :if-does-not-exist :create)
      (let ((*print-pretty* t)
            (*print-readably* t))
        (write dados :stream arquivo)
        (terpri arquivo)))
    (format t "~&Cena salva em ~a~%" caminho)
    caminho))

(defun corpo-de-dados (dados)
  (when dados
    (make-corpo-fisico
     :dinamico-p (getf dados :dinamico-p)
     :solido-p (getf dados :solido-p t)
     :usar-gravidade-p (getf dados :usar-gravidade-p t)
     :restituicao (getf dados :restituicao 0.0)
     :atrito (getf dados :atrito 0.12)
     :massa (getf dados :massa 1.0))))

(defun malha-para-dados-entidade (dados)
  (case (getf dados :tipo)
    (:cubo *malha-cubo*)
    (:piramide *malha-piramide*)
    (:obj
     (let ((fonte (getf dados :fonte-malha)))
       (when fonte
         (carregar-obj fonte :nome (getf dados :nome "obj")))))
    (otherwise
     ;; Malhas personalizadas arbitrarias nao sao embutidas no arquivo nesta
     ;; versao. Isso evita transformar o save em um segundo formato de asset.
     nil)))

(defun entidade-de-dados (dados)
  (make-entidade
   :nome (getf dados :nome "entidade")
   :tipo (getf dados :tipo :personalizada)
   :fonte-malha (getf dados :fonte-malha)
   :malha (malha-para-dados-entidade dados)
   :transformacao
   (make-transformacao
    :posicao (lista->vetor (getf dados :posicao '(0 0 0)))
    :rotacao (lista->vetor (getf dados :rotacao '(0 0 0)))
    :escala (lista->vetor (getf dados :escala '(1 1 1))))
   :cor (lista->vetor (getf dados :cor '(0.8 0.8 0.8)))
   :velocidade (lista->vetor (getf dados :velocidade '(0 0 0)))
   :velocidade-rotacao
   (lista->vetor (getf dados :velocidade-rotacao '(0 0 0)))
   :corpo (corpo-de-dados (getf dados :corpo))
   :tags (copy-list (getf dados :tags '()))
   :ativo-p (getf dados :ativo-p t)
   :visivel-p (getf dados :visivel-p t)))

(defun aplicar-configuracao-de-dados (dados)
  (when dados
    (setf (configuracao-motor-fov *configuracao*)
          (getf dados :fov 60.0)
          (configuracao-motor-plano-proximo *configuracao*)
          (getf dados :plano-proximo 0.05)
          (configuracao-motor-plano-distante *configuracao*)
          (getf dados :plano-distante 300.0)
          (configuracao-motor-gravidade *configuracao*)
          (getf dados :gravidade -9.81)
          (configuracao-motor-velocidade-dia *configuracao*)
          (getf dados :velocidade-dia 0.08)
          (configuracao-motor-ciclo-dia-noite-p *configuracao*)
          (getf dados :ciclo-dia-noite-p t)
          (configuracao-motor-mostrar-grade-p *configuracao*)
          (getf dados :mostrar-grade-p t)
          (configuracao-motor-mostrar-eixos-p *configuracao*)
          (getf dados :mostrar-eixos-p t)
          (configuracao-motor-mostrar-mira-p *configuracao*)
          (getf dados :mostrar-mira-p t))
    (let ((cor (getf dados :cor-ceu-fixa nil)))
      (setf (configuracao-motor-cor-ceu-fixa *configuracao*)
            (and cor (lista->vetor cor))))))

(defun carregar-cena (caminho)
  "Substitui a cena atual por uma cena salva pelo LIMIAR 3D."
  (let ((*read-eval* nil))
    (with-open-file (arquivo caminho :direction :input)
      (let ((dados (read arquivo nil nil)))
        (unless (and dados (eq (getf dados :formato) :limiar3d-cena))
          (error "O arquivo ~a nao parece ser uma cena do Limiar 3D." caminho))

        (setf *entidades* '()
              *regras* '()
              *proximo-id* 1
              *hora-do-dia* (getf dados :hora-do-dia 10.0)
              *tempo-mundo* (getf dados :tempo-mundo 0.0))

        (aplicar-configuracao-de-dados (getf dados :configuracao))

        (let* ((camera-dados (getf dados :camera))
               (posicao
                 (lista->vetor (getf camera-dados :posicao '(0 2 9))))
               (rotacao
                 (lista->vetor (getf camera-dados :rotacao '(-7 0 0)))))
          (setf *camera-inicial-posicao* posicao
                *camera-inicial-rotacao* rotacao
                *camera*
                (make-camera :posicao posicao :rotacao rotacao)))

        (dolist (entidade-dados (getf dados :entidades '()))
          (let ((entidade (entidade-de-dados entidade-dados)))
            (when (entidade-malha entidade)
              (adicionar-entidade entidade)))))))
  (format t "~&Cena carregada de ~a (~d entidades).~%"
          caminho (length *entidades*))
  *entidades*)


;;; ==========================================================================
;;; 14. PREPARACAO DE CENAS E CENA DE DEMONSTRACAO
;;; ==========================================================================

(defun preparar-cena-vazia ()
  "Limpa completamente o mundo sem criar geometria de demonstracao.

Esta e a base recomendada para exemplos e jogos que querem construir um
ambiente realmente proprio. Reinicia entidades, regras, relogio, entrada,
camera e configuracao visual para valores previsiveis."
  (setf *entidades* '()
        *regras* '()
        *proximo-id* 1
        *pausado-p* nil
        *modo-aramado-p* nil
        *hora-do-dia* 10.0
        *tempo-mundo* 0.0
        *entidade-em-mira* nil
        *configuracao* (make-configuracao-motor)
        *camera-inicial-posicao* (v3 0.0 2.0 9.0)
        *camera-inicial-rotacao* (v3 -7.0 0.0 0.0))
  (clrhash *teclas-pressionadas*)
  (clrhash *teclas-especiais-pressionadas*)
  (setf *mouse-olhando-p* nil)
  (reiniciar-camera)
  *entidades*)

(defun configurar-camera (&key
                            (posicao (v3 0.0 2.0 9.0))
                            (rotacao (v3 -7.0 0.0 0.0)))
  "Define camera inicial de uma cena e zera qualquer inercia anterior."
  (setf *camera-inicial-posicao* posicao
        *camera-inicial-rotacao* rotacao
        (camera-posicao *camera*) posicao
        (camera-rotacao *camera*) rotacao
        (camera-velocidade *camera*) (v3 0.0 0.0 0.0)
        (camera-velocidade-angular *camera*) (v3 0.0 0.0 0.0))
  *camera*)

(defun configurar-ambiente (&key
                              (hora *hora-do-dia*)
                              (ciclo-dia-noite-p
                               (configuracao-motor-ciclo-dia-noite-p
                                *configuracao*))
                              (velocidade-dia
                               (configuracao-motor-velocidade-dia
                                *configuracao*))
                              (gravidade
                               (configuracao-motor-gravidade
                                *configuracao*))
                              (mostrar-grade-p
                               (configuracao-motor-mostrar-grade-p
                                *configuracao*))
                              (mostrar-eixos-p
                               (configuracao-motor-mostrar-eixos-p
                                *configuracao*))
                              (mostrar-mira-p
                               (configuracao-motor-mostrar-mira-p
                                *configuracao*))
                              (cor-ceu nil cor-ceu-fornecida-p))
  "Configura as caracteristicas globais que dao identidade visual/fisica a cena.

COR-CEU, quando fornecida, congela uma cor especifica. Se omitida, o ceu volta
a ser calculado pelo ciclo dia/noite."
  (setf *hora-do-dia* (mod hora 24.0)
        (configuracao-motor-ciclo-dia-noite-p *configuracao*) ciclo-dia-noite-p
        (configuracao-motor-velocidade-dia *configuracao*) velocidade-dia
        (configuracao-motor-gravidade *configuracao*) gravidade
        (configuracao-motor-mostrar-grade-p *configuracao*) mostrar-grade-p
        (configuracao-motor-mostrar-eixos-p *configuracao*) mostrar-eixos-p
        (configuracao-motor-mostrar-mira-p *configuracao*) mostrar-mira-p)
  (when cor-ceu-fornecida-p
    (setf (configuracao-motor-cor-ceu-fixa *configuracao*) cor-ceu))
  *configuracao*)


(defun cor-aleatoria-suave ()
  (v3 (+ 0.25 (* 0.65 (random 1.0)))
      (+ 0.25 (* 0.65 (random 1.0)))
      (+ 0.25 (* 0.65 (random 1.0)))))

(defun reiniciar-cena ()
  "Apaga a cena e cria uma demonstracao dos principais sistemas."
  (preparar-cena-vazia)
  (configurar-ambiente :hora 10.0 :ciclo-dia-noite-p t
                       :mostrar-grade-p t :mostrar-eixos-p t)

  ;; Chao estatico para a fisica.
  (adicionar-entidade (criar-chao))

  ;; Nucleo central: interagivel e flutuante.
  (let ((nucleo
          (adicionar-entidade
           (criar-cubo
            :nome "nucleo"
            :posicao (v3 0.0 0.3 0.0)
            :escala (v3 1.5 1.5 1.5)
            :cor (v3 0.22 0.68 1.0)
            :velocidade-rotacao (v3 18.0 35.0 8.0)
            :tags '(:interagivel :nucleo)))))
    (adicionar-comportamento nucleo
                             (comportamento-flutuar
                              :altura 0.18 :velocidade 1.7))
    (definir-dado nucleo :estado :estavel)
    (setf (entidade-ao-interagir nucleo)
          (lambda (entidade)
            (let ((estado (obter-dado entidade :estado :estavel)))
              (if (eq estado :estavel)
                  (progn
                    (definir-dado entidade :estado :desperto)
                    (setf (entidade-cor entidade) (v3 1.0 0.22 0.72)
                          (entidade-velocidade-rotacao entidade)
                          (v3 70.0 125.0 25.0))
                    (format t "  O nucleo foi DESPERTO pelo jogador.~%"))
                  (progn
                    (definir-dado entidade :estado :estavel)
                    (setf (entidade-cor entidade) (v3 0.22 0.68 1.0)
                          (entidade-velocidade-rotacao entidade)
                          (v3 18.0 35.0 8.0))
                    (format t "  O nucleo voltou ao estado ESTAVEL.~%")))))))

  ;; Piramide estatica.
  (adicionar-entidade
   (criar-piramide
    :nome "obelisco"
    :posicao (v3 -4.0 0.0 -3.0)
    :escala (v3 1.8 3.8 1.8)
    :cor (v3 0.78 0.42 0.94)
    :velocidade-rotacao (v3 0.0 9.0 0.0)
    :fisico-p t
    :dinamico-p nil
    :tags '(:cenario :interagivel)))

  ;; Alguns corpos fisicos para mostrar gravidade e colisao.
  (loop for i from 0 below 5
        do (adicionar-entidade
            (criar-cubo
             :nome (format nil "caixa-~d" i)
             :posicao (v3 (+ 2.5 (* 0.75 i))
                           (+ 1.0 (* 1.1 i))
                           -2.5)
             :escala (v3 0.7 0.7 0.7)
             :cor (cor-aleatoria-suave)
             :velocidade-rotacao (v3 (* 4.0 i) 10.0 (* 2.0 i))
             :fisico-p t
             :dinamico-p t
             :restituicao 0.08
             :atrito 0.2
             :tags '(:fisica :caixa))))

  ;; Pequena lua/orbe que usa um comportamento Lisp em runtime.
  (let ((orbe
          (adicionar-entidade
           (criar-piramide
            :nome "orbe-orbital"
            :posicao (v3 3.5 2.5 0.0)
            :escala (v3 0.45 0.45 0.45)
            :cor (v3 1.0 0.84 0.25)
            :velocidade-rotacao (v3 80.0 35.0 40.0)
            :tags '(:orbita)))))
    (adicionar-comportamento
     orbe
     (comportamento-orbitar (v3 0.0 0.0 0.0) 3.6 28.0 2.2)))

  *entidades*)


;;; ==========================================================================
;;; 15. ESTADO E AJUDA
;;; ==========================================================================

(defun mostrar-estado ()
  (format t "~%=== ~a v~a ===~%" +nome-motor+ +versao-motor+)
  (format t "FPS: ~,1f~%" *fps-atual*)
  (format t "Entidades: ~d~%" (length *entidades*))
  (format t "Regras: ~d~%" (length *regras*))
  (format t "Tempo de mundo: ~,2fs~%" *tempo-mundo*)
  (format t "Hora do dia: ~,2f h~%" *hora-do-dia*)
  (format t "Fisica dinamica: ~d corpos~%"
          (count-if #'corpo-dinamico-p *entidades*))
  (let ((p (camera-posicao *camera*))
        (r (camera-rotacao *camera*)))
    (format t "Camera pos: (~,2f ~,2f ~,2f)~%"
            (vetor3-x p) (vetor3-y p) (vetor3-z p))
    (format t "Camera rot: (~,1f ~,1f ~,1f)~%"
            (vetor3-x r) (vetor3-y r) (vetor3-z r))
    (let ((v (camera-velocidade *camera*)))
      (format t "Camera vel: (~,2f ~,2f ~,2f)~%"
              (vetor3-x v) (vetor3-y v) (vetor3-z v))))
  (format t "Mouse olhando por arrasto: ~:[nao~;sim~]~%" *mouse-olhando-p*)
  (when *entidade-em-mira*
    (format t "Na mira: ~a [id ~d]~%"
            (entidade-nome *entidade-em-mira*)
            (entidade-id *entidade-em-mira*)))
  (format t "=====================~%~%"))

(defun mostrar-ajuda ()
  (format t "~%~a v~a - controles~%" +nome-motor+ +versao-motor+)
  (format t "  Arrastar esq: olhar com a camera~%")
  (format t "  Clique esq  : interagir (sem arrastar)~%")
  (format t "  W/S         : frente/tras na direcao da camera~%")
  (format t "  A/D         : strafe relativo a camera~%")
  (format t "  Q/E         : descer/subir (segure)~%")
  (format t "  Shift       : turbo~%")
  (format t "  Setas/IJKL  : olhar pelo teclado~%")
  (format t "  Clique dir  : lancar cubo fisico~%")
  (format t "  [/]         : diminuir/aumentar FOV~%")
  (format t "  C           : lancar cubo fisico~%")
  (format t "  F           : interagir com objeto na mira~%")
  (format t "  T           : aramado/solido~%")
  (format t "  G           : mostrar/esconder grade~%")
  (format t "  O           : mostrar/esconder eixos~%")
  (format t "  N           : ciclo dia/noite~%")
  (format t "  P           : pausar~%")
  (format t "  B           : estado no terminal~%")
  (format t "  R           : reconstruir ambiente atual~%")
  (format t "  X           : camera inicial do ambiente~%")
  (format t "  H           : ajuda~%")
  (format t "  ESC         : sair~%~%")
  (format t "REPL: salvar-cena, carregar-cena, adicionar-regra,~%")
  (format t "      adicionar-comportamento, entidades-com-tag, etc.~%~%"))


;;; ==========================================================================
;;; 16. JANELA, OPENGL E LOOP
;;; ==========================================================================

(defclass janela-limiar (glut:window)
  ()
  (:default-initargs
   :width +largura-inicial+
   :height +altura-inicial+
   :pos-x 70
   :pos-y 50
   :mode '(:double :rgb :depth)
   :title "Limiar 3D - Common Lisp"
   :tick-interval (round 1000 +fps-alvo+)))

(defun inicializar-opengl ()
  (gl:clear-color 0.02 0.03 0.06 1.0)
  (gl:clear-depth 1.0)
  (gl:enable :depth-test)
  (gl:depth-func :lequal)
  (gl:shade-model :flat)
  (gl:hint :perspective-correction-hint :nicest))

(defun atualizar-projecao (largura altura)
  (let ((altura-segura (max altura 1)))
    (gl:viewport 0 0 largura altura-segura)
    (gl:matrix-mode :projection)
    (gl:load-identity)
    (glu:perspective
     (configuracao-motor-fov *configuracao*)
     (/ (float largura 1.0)
        (float altura-segura 1.0))
     (configuracao-motor-plano-proximo *configuracao*)
     (configuracao-motor-plano-distante *configuracao*))
    (gl:matrix-mode :modelview)
    (gl:load-identity)))

(defmethod glut:display-window :before ((janela janela-limiar))
  (declare (ignore janela))
  (inicializar-opengl)
  ;; O cursor permanece normal. A camera so responde a clique + arraste.
  (glut:set-cursor :cursor-inherit))

(defmethod glut:display ((janela janela-limiar))
  (declare (ignore janela))
  (renderizar-mundo))

(defmethod glut:reshape ((janela janela-limiar) largura altura)
  (declare (ignore janela))
  (setf *largura-janela* largura
        *altura-janela* altura)
  (atualizar-projecao largura altura))

(defmethod glut:tick ((janela janela-limiar))
  (declare (ignore janela))
  (let ((delta (calcular-delta-frame)))
    (atualizar-mundo delta)
    (atualizar-fps))
  (unless (= 0 (glut:get-window))
    (glut:post-redisplay)))

(defun mudar-fov (delta)
  (setf (configuracao-motor-fov *configuracao*)
        (limitar (+ (configuracao-motor-fov *configuracao*) delta)
                 25.0 110.0))
  (atualizar-projecao *largura-janela* *altura-janela*)
  (format t "~&FOV = ~,1f graus.~%"
          (configuracao-motor-fov *configuracao*)))

(defun tecla-de-movimento-p (tecla)
  (find tecla "wasdqejlik" :test #'char=))

(defun reconstruir-cena-atual ()
  "Executa novamente o construtor usado para abrir a cena atual."
  (if *construtor-cena-atual*
      (funcall *construtor-cena-atual*)
      (reiniciar-cena)))

(defun executar-acao-tecla (tecla)
  "Executa apenas comandos de disparo unico. Movimento e feito no TICK."
  (case tecla
    (#\[ (mudar-fov -3.0))
    (#\] (mudar-fov +3.0))
    (#\c (lancar-cubo))
    (#\f (interagir-com-mira))
    (#\t (setf *modo-aramado-p* (not *modo-aramado-p*)))
    (#\g
     (setf (configuracao-motor-mostrar-grade-p *configuracao*)
           (not (configuracao-motor-mostrar-grade-p *configuracao*))))
    (#\o
     (setf (configuracao-motor-mostrar-eixos-p *configuracao*)
           (not (configuracao-motor-mostrar-eixos-p *configuracao*))))
    (#\n
     (setf (configuracao-motor-ciclo-dia-noite-p *configuracao*)
           (not (configuracao-motor-ciclo-dia-noite-p *configuracao*))))
    (#\p (setf *pausado-p* (not *pausado-p*)))
    (#\b (mostrar-estado))
    (#\r (reconstruir-cena-atual))
    (#\x (reiniciar-camera))
    (#\h (mostrar-ajuda))
    (#\Esc (glut:destroy-current-window))))

(defmethod glut:keyboard ((janela janela-limiar) tecla x y)
  (declare (ignore janela x y))
  (let* ((normalizada (char-downcase tecla))
         (ja-pressionada (gethash normalizada *teclas-pressionadas*)))
    ;; Marcar primeiro impede a repeticao automatica do SO de repetir toggles.
    (setf (gethash normalizada *teclas-pressionadas*) t)
    (unless (or ja-pressionada
                (tecla-de-movimento-p normalizada))
      (executar-acao-tecla normalizada)))

  (unless (= 0 (glut:get-window))
    (glut:post-redisplay)))

(defmethod glut:keyboard-up ((janela janela-limiar) tecla x y)
  (declare (ignore janela x y))
  (remhash (char-downcase tecla) *teclas-pressionadas*))

(defmethod glut:special ((janela janela-limiar) tecla x y)
  (declare (ignore janela x y))
  (setf (gethash tecla *teclas-especiais-pressionadas*) t))

(defmethod glut:special-up ((janela janela-limiar) tecla x y)
  (declare (ignore janela x y))
  (remhash tecla *teclas-especiais-pressionadas*))

(defmethod glut:motion ((janela janela-limiar) x y)
  "Movimento ativo: o GLUT chama este callback enquanto algum botao esta pressionado."
  (declare (ignore janela))
  (atualizar-arrasto-camera x y))

(defmethod glut:mouse ((janela janela-limiar) botao estado x y)
  (declare (ignore janela))
  (case botao
    (:left-button
     (cond
       ((eq estado :down)
        (iniciar-arrasto-camera x y))
       ((eq estado :up)
        ;; Um clique curto continua servindo para interagir. Um arrasto olha.
        (when (finalizar-arrasto-camera)
          (interagir-com-mira)))))

    (:right-button
     (when (eq estado :down)
       (lancar-cubo)))))


;;; ==========================================================================
;;; 17. PONTO DE ENTRADA
;;; ==========================================================================

(defun iniciar (&key (construtor-cena #'reiniciar-cena))
  "Abre a janela e inicia o Limiar 3D.

CONSTRUTOR-CENA e uma funcao sem argumentos executada antes da abertura da
janela. O padrao e REINICIAR-CENA. Passe NIL para preservar a cena que ja foi
montada pelo REPL."
  (when construtor-cena
    (setf *construtor-cena-atual* construtor-cena)
    (funcall construtor-cena))
  (setf *tempo-frame-anterior* nil
        *inicio-periodo-fps* nil
        *frames-no-periodo* 0
        *fps-atual* 0.0
        *mouse-olhando-p* nil
        *mouse-arrasto-acumulado* 0.0)
  (clrhash *teclas-pressionadas*)
  (clrhash *teclas-especiais-pressionadas*)
  (mostrar-ajuda)
  (format t "Iniciando ~a v~a...~%" +nome-motor+ +versao-motor+)
  (format t "Entidades na cena: ~d~%~%" (length *entidades*))
  (glut:display-window (make-instance 'janela-limiar)))


;;; ==========================================================================
;;; 18. EXEMPLOS PARA O REPL
;;; ==========================================================================
;;;
;;; O objetivo do Limiar 3D e ser hackeavel enquanto roda. Alguns exemplos:
;;;
;;; 1) Encontrar e mudar o nucleo:
;;;
;;;   (let ((n (limiar3d:encontrar-entidade "nucleo")))
;;;     (setf (limiar3d::entidade-cor n)
;;;           (limiar3d:v3 0.1 1.0 0.3)))
;;;
;;; 2) Criar dez cubos fisicos:
;;;
;;;   (dotimes (i 10)
;;;     (limiar3d:adicionar-entidade
;;;       (limiar3d:criar-cubo
;;;         :nome (format nil "chuva-~d" i)
;;;         :posicao (limiar3d:v3 (- (random 8.0) 4.0)
;;;                               (+ 5.0 (random 8.0))
;;;                               (- (random 8.0) 4.0))
;;;         :fisico-p t
;;;         :dinamico-p t)))
;;;
;;; 3) Regra metafisica: quando passar de 18h, gravidade fica invertida.
;;;
;;;   (limiar3d:adicionar-regra
;;;     (limiar3d:criar-regra
;;;       "gravidade-da-noite"
;;;       (lambda () (> limiar3d:*hora-do-dia* 18.0))
;;;       (lambda ()
;;;         (setf (limiar3d::configuracao-motor-gravidade
;;;                limiar3d:*configuracao*)
;;;               4.0)
;;;         (format t "A gravidade foi invertida.~%"))
;;;       :uma-vez-p t))
;;;
;;; 4) Salvar e carregar:
;;;
;;;   (limiar3d:salvar-cena "meu-mundo.l3d")
;;;   (limiar3d:carregar-cena "meu-mundo.l3d")
;;;
;;; 5) Carregar OBJ e adiciona-lo a cena:
;;;
;;;   (let* ((arquivo "modelo.obj")
;;;          (m (limiar3d:carregar-obj arquivo :nome "modelo")))
;;;     (limiar3d:adicionar-entidade
;;;       (limiar3d::criar-entidade-de-malha
;;;         m
;;;         :nome "modelo"
;;;         :tipo :obj
;;;         :fonte-malha arquivo
;;;         :posicao (limiar3d:v3 0.0 0.0 -5.0)
;;;         :cor (limiar3d:v3 0.7 0.9 1.0))))
;;;
;;; 6) Consultar todas as caixas fisicas:
;;;
;;;   (limiar3d:entidades-com-tag :fisica)
;;;
;;; Fim do arquivo.
