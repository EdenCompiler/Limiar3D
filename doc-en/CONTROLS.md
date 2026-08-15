# Controls and camera model

Keyboard callbacks only update held-key state. Actual movement is calculated every frame from delta time.

`W/S` use the exact visual forward vector returned by `direcao-camera`; `A/D` use the transformed camera-local right axis. Movement direction changes immediately when the camera rotates, while scalar speed is smoothed separately.

Mouse look uses active GLUT motion and therefore only rotates the view while the left mouse button is held. A short left click remains an interaction.
