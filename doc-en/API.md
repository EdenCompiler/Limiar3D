# Limiar 3D API

The supported public surface is exported from package `limiar3d`. Symbols referenced with `limiar3d::` are internal and may change.

## Startup

```lisp
(limiar3d:iniciar)
(limiar3d:iniciar :construtor-cena #'my-scene)
```

The scene constructor is a no-argument function called before the window opens. Pass `NIL` to preserve a scene prepared from the REPL.


## Environment authoring

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

`preparar-cena-vazia` clears entities, rules, clock, input state, and environment configuration without creating demo geometry. It is the recommended starting point for a world with its own identity.

`configurar-camera` also records the scene's reset camera, so `X` returns to it. The constructor passed to `iniciar` is remembered, so `R` rebuilds the current environment rather than replacing it with the built-in demo.

## Core constructors

```lisp
(limiar3d:v3 x y z)
(limiar3d:criar-cubo ...)
(limiar3d:criar-piramide ...)
(limiar3d:criar-chao ...)
(limiar3d:adicionar-entidade entity)
(limiar3d:remover-entidade entity)
(limiar3d:encontrar-entidade "name")
```

## Behavior and metadata

```lisp
(limiar3d:adicionar-comportamento entity function)
(limiar3d:definir-dado entity :health 100)
(limiar3d:obter-dado entity :health 0)
```

## Rules

```lisp
(limiar3d:adicionar-regra
 (limiar3d:criar-regra name condition action :uma-vez-p t))
```

## Camera and interaction

```lisp
(limiar3d:direcao-camera)
(limiar3d:direita-camera)
(limiar3d:entidade-na-mira)
(limiar3d:interagir-com-mira)
```

## Persistence

```lisp
(limiar3d:salvar-cena "world.l3d")
(limiar3d:carregar-cena "world.l3d")
```
