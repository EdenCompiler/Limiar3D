# Limiar 3D architecture

The complete engine stays in `limiar3d.lisp`. Internal organization is section-based rather than file-based. This is both a teaching choice and a project constraint.

## Main flow

```text
GLUT -> input callbacks -> held-key state -> frame tick/delta
                                        |
                 +----------------------+----------------------+
                 |                      |                      |
                 v                      v                      v
              camera                 behaviors              physics/AABB
                 +----------------------+----------------------+
                                        |
                                        v
                                  global rules
                                        |
                                        v
                                     raycast
                                        |
                                        v
                                      render
                                        |
                                        v
                                   OpenGL/GLUT
```

## Camera consistency

`vetor-local-camera->mundo` is the key camera transform. Visual forward, raycast forward, and `W/S` all derive from it, preventing the renderer and movement code from disagreeing about where the camera is looking.

## Physics

Physics is intentionally small: velocity integration, gravity, AABBs, and axis-based resolution. It is useful for prototypes and small games, not a replacement for a full rigid-body engine.

## Rendering

The default renderer uses classic OpenGL immediate mode and CPU Lambert shading. This keeps the graphics path readable at the cost of modern performance.

## Why one engine file?

Because the project is meant to be readable as a continuous program. The repository is modular around the engine; the engine itself remains single-file by design.
