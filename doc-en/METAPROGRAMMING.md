# Metaprogramming and world rules

Limiar 3D intentionally keeps the boundary between game state and executable Lisp thin. Entities can hold behavior closures, and global rules are condition/action closures evaluated by the simulation.

This is useful for ordinary development tooling, but it also enables game designs where discovering and changing the rules of the world is itself a mechanic.
