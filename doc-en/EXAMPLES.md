# Examples

Run any example from the repository root:

```sh
sbcl --load ~/quicklisp/setup.lisp --script scripts/run-example.lisp observatorio-do-alvorecer
```

Since v0.2.6, every example is a **fully independent environment**. They no longer start from the engine's built-in demo and add a few objects. Each example calls `preparar-cena-vazia`, chooses its own camera/environment settings, and builds its own geometry from scratch.

## `observatorio-do-alvorecer` — Dawn Observatory

A bright open plaza with four pillars, an interactable central astrolabe, and orbiting celestial markers. It focuses on navigation, interaction, raycasting, and simple runtime behaviors.

## `deposito-de-impacto` — Impact Warehouse

A dark enclosed industrial hall with walls, loading docks, stacked cargo, and falling dynamic containers. It focuses on gravity, AABB collisions, friction, restitution, and many moving bodies.

## `templo-do-eclipse` — Eclipse Temple

Separated floating altars in a purple void. A central eye and twelve sigils move through Lisp closures. Timed global rules reverse gravity and later change the sky, making the world's laws part of the scene.

## `arquipelago-suspenso` — Floating Archipelago

A vertical world with no global floor: five islands at different heights, incomplete bridges, a lighthouse, crystal garden, and orbiting gliders. It demonstrates custom world composition and vertical exploration.

## `galeria-do-monolito` — Monolith Gallery

A long enclosed museum built from engine primitives. The main exhibit loads `monolito.obj`, while side exhibits reuse the new `cristal.obj` mesh. It demonstrates mixing procedural architecture with external OBJ assets.

## Starting your own environment

Prefer an empty scene when authoring a new world:

```lisp
(defun my-scene ()
  (limiar3d:preparar-cena-vazia)
  (limiar3d:configurar-ambiente
   :ciclo-dia-noite-p nil
   :cor-ceu (limiar3d:v3 0.25 0.45 0.70))
  (limiar3d:configurar-camera
   :posicao (limiar3d:v3 0.0 3.0 12.0)
   :rotacao (limiar3d:v3 -8.0 0.0 0.0)))

(limiar3d:iniciar :construtor-cena #'my-scene)
```

`R` rebuilds the currently loaded environment, and `X` returns to the initial camera registered by that environment.
