# API do Limiar 3D

Este documento cobre a superfície pública principal. Funções com `limiar3d::` são internas e podem mudar entre versões.

## Inicialização

```lisp
(limiar3d:iniciar)
(limiar3d:iniciar :construtor-cena #'minha-cena)
```

`CONSTRUTOR-CENA` é uma função sem argumentos chamada antes de a janela abrir. Passe `NIL` para preservar uma cena já preparada no REPL.


## Autoria de ambientes

```lisp
(limiar3d:preparar-cena-vazia)
(limiar3d:configurar-ambiente
 :hora 15.0
 :gravidade -9.81
 :ciclo-dia-noite-p nil
 :cor-ceu (limiar3d:v3 0.3 0.6 0.9))
(limiar3d:configurar-camera
 :posicao (limiar3d:v3 0.0 3.0 12.0)
 :rotacao (limiar3d:v3 -8.0 0.0 0.0))
```

`preparar-cena-vazia` limpa entidades, regras, relógio, entrada e configuração sem criar geometria. É a base recomendada para um jogo ou exemplo que queira identidade própria.

`configurar-camera` também registra a câmera inicial da cena; por isso `X` retorna para ela. O construtor passado a `iniciar` é memorizado; por isso `R` reconstrói a cena atual em vez de abrir a demo padrão.

## Vetores

```lisp
(limiar3d:v3 x y z)
```

## Entidades e primitivas

```lisp
(limiar3d:criar-cubo ...)
(limiar3d:criar-piramide ...)
(limiar3d:criar-chao ...)
(limiar3d:adicionar-entidade entidade)
(limiar3d:remover-entidade entidade)
(limiar3d:encontrar-entidade "nome")
(limiar3d:entidades-com-tag :tag)
```

Cubos e pirâmides aceitam posição, rotação, escala, cor e opções físicas. Consulte os lambdas no próprio arquivo para a lista exata de keywords da versão instalada.

## OBJ

```lisp
(defparameter *malha*
  (limiar3d:carregar-obj "modelo.obj" :nome "modelo"))

(limiar3d:adicionar-entidade
 (limiar3d:criar-entidade-de-malha
  *malha* :nome "objeto" :tipo :obj))
```

O loader suporta vértices, índices positivos/negativos e triangulação em leque. Não carrega MTL, UVs ou texturas nesta versão.

## Comportamentos

```lisp
(limiar3d:adicionar-comportamento entidade funcao)
(limiar3d:comportamento-flutuar :altura 0.3 :velocidade 1.0)
(limiar3d:comportamento-orbitar centro raio velocidade altura)
```

A função recebe `(entidade delta)` a cada frame.

## Metadados

```lisp
(limiar3d:definir-dado entidade :vida 100)
(limiar3d:obter-dado entidade :vida 0)
```

## Regras globais

```lisp
(limiar3d:adicionar-regra
 (limiar3d:criar-regra nome condicao acao :uma-vez-p t))
(limiar3d:limpar-regras)
```

## Câmera e interação

```lisp
(limiar3d:direcao-camera)
(limiar3d:direita-camera)
(limiar3d:entidade-na-mira)
(limiar3d:interagir-com-mira)
```

## Persistência

```lisp
(limiar3d:salvar-cena "mundo.l3d")
(limiar3d:carregar-cena "mundo.l3d")
```

## Estado exposto

`*entidades*`, `*regras*`, `*camera*`, `*hora-do-dia*` e `*configuracao*` são exportados de propósito para experimentação pelo REPL.
