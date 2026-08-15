# Scenes and persistence

`.l3d` files are human-readable S-expressions.

## Empty scene versus built-in demo

`reiniciar-cena` creates the engine's official demo. New environments should normally start with:

```lisp
(limiar3d:preparar-cena-vazia)
(limiar3d:configurar-ambiente ...)
(limiar3d:configurar-camera ...)
```

This prevents unrelated worlds from accidentally sharing the same floor, central object, or reset camera. All five repository examples follow this pattern since v0.2.6.

Use:

```lisp
(limiar3d:salvar-cena "world.l3d")
(limiar3d:carregar-cena "world.l3d")
```

Serializable entity/configuration data is persisted, including a fixed environment sky color when one is configured. Arbitrary closures and runtime callbacks cannot be portably reconstructed and should be reinstalled by application code after loading.
