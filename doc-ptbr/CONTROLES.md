# Controles e modelo da câmera

## Entrada contínua

O teclado não move a câmera diretamente nos callbacks `keyboard`. Esses callbacks apenas atualizam tabelas de teclas pressionadas. O movimento real ocorre em `atualizar-controles-camera` usando o `delta` do frame. Isso evita depender do auto-repeat do sistema operacional.

## `W/S` seguem a visão

`direcao-camera` transforma o vetor local `(0, 0, -1)` para o mundo usando a inversa da mesma ordem de rotações aplicada à view OpenGL. O raycast usa essa direção e `W` também.

Consequência: se o centro da tela aponta para cima e à esquerda, `W` avança para cima e à esquerda.

## `A/D`

O strafe usa o eixo local `(1, 0, 0)` transformado pela câmera. Assim, a lateral acompanha a orientação sem depender dos eixos globais.

## Mouse

O motor usa `glut:motion`, não movimento passivo. Portanto, a câmera só gira enquanto o botão esquerdo está pressionado. Um deslocamento abaixo de `+limiar-arrasto-mouse+` é tratado como clique e dispara interação ao soltar.

## Suavização

A velocidade escalar acelera/freia suavemente. A direção, porém, acompanha a câmera imediatamente. Essa separação evita a sensação de continuar deslizando para uma direção antiga depois de virar a cabeça.
