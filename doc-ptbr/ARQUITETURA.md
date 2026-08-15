# Arquitetura do Limiar 3D

O Limiar 3D mantém o motor completo em `limiar3d.lisp`. A organização interna é feita por seções, não por dezenas de arquivos. Isso é uma escolha didática e também uma característica do projeto.

## Fluxo principal

```text
GLUT -> callbacks de entrada -> estado das teclas
                         |
                         v
                   tick / delta real
                         |
       +-----------------+------------------+
       |                 |                  |
       v                 v                  v
   controles       comportamentos        física
   da câmera        das entidades        + AABB
       |                 |                  |
       +-----------------+------------------+
                         |
                         v
                   regras globais
                         |
                         v
                     raycast
                         |
                         v
                    renderização
                         |
                         v
                    OpenGL/GLUT
```

## Sistemas internos

### Matemática

`vetor3` é a unidade básica. O motor implementa soma, subtração, escala, produto escalar, produto vetorial, normalização e rotações Euler.

### Entidades

Uma `entidade` agrega malha, transformação, cor, velocidade, corpo físico opcional, tags, metadados e uma lista de closures de comportamento. Não existe uma árvore de herança profunda.

### Câmera e movimento

O ponto mais importante da câmera é `vetor-local-camera->mundo`. A mesma transformação fundamenta `direcao-camera`, o raycast e o movimento `W/S`. Assim, o centro visual da tela e a direção de avanço não são modelos separados.

### Física

A física é deliberadamente simples: integração por velocidade, gravidade, AABBs e resolução por eixo. Serve para pequenos jogos e protótipos, não para substituir Bullet, Jolt ou PhysX.

### Regras

Uma regra contém uma condição e uma ação Lisp. A cada atualização, regras habilitadas podem alterar qualquer parte do estado exposto do motor. É aqui que a natureza de metaprogramação do projeto aparece de forma mais direta.

### Renderização

O renderer usa o pipeline fixo do OpenGL. Cada entidade aplica translate/rotate/scale e envia triângulos imediatamente. O sombreamento Lambert é calculado na CPU. Esta arquitetura é simples de estudar, mas não é apropriada para grandes quantidades de geometria.

## Por que um único arquivo?

Porque o objetivo é permitir que uma pessoa leia o motor como um programa contínuo. O repositório é modular na distribuição; o motor é monolítico por design.
