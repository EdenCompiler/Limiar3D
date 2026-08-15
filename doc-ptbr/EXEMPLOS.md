# Exemplos

Todos os exemplos podem ser executados pela raiz do repositório:

```sh
sbcl --load ~/quicklisp/setup.lisp --script scripts/run-example.lisp observatorio-do-alvorecer
```

A partir da v0.2.6, cada exemplo é um **ambiente completo e independente**. Nenhum deles começa chamando `reiniciar-cena` para herdar a mesma praça, núcleo ou caixas da demo interna. Cada cena usa `preparar-cena-vazia`, escolhe sua própria câmera e ambiente e então constrói geometria própria.

## `observatorio-do-alvorecer` — Observatório do Alvorecer

Uma praça aberta, clara e simétrica. Quatro pilares cercam um astrolábio central interagível e pequenos marcadores orbitam o centro.

Demonstra principalmente:

- navegação e mouse-look;
- `WASD` relativo à câmera;
- raycast/interação;
- comportamentos orbitais;
- composição de uma cena simples sem herdar a demo do motor.

## `deposito-de-impacto` — Depósito de Impacto

Um galpão industrial fechado com piso, paredes, docas, pilhas de carga e uma sequência de contêineres caindo sob gravidade mais forte.

Demonstra:

- corpos estáticos e dinâmicos;
- AABB;
- gravidade, atrito e restituição;
- pilhas e colisões em quantidade;
- ambiente fechado construído com primitivas.

## `templo-do-eclipse` — Templo do Eclipse

Cinco altares separados flutuam no vazio. Um olho central e doze sigilos se movem por closures Lisp. Relicários físicos deixam mudanças nas leis do mundo imediatamente visíveis.

Depois de alguns segundos:

1. a gravidade muda de sentido;
2. o céu muda para a segunda fase do eclipse.

Demonstra:

- regras globais;
- closures como comportamento;
- mudança de configuração em runtime;
- física em um mundo sem piso global;
- estado do mundo como parte da mecânica.

## `arquipelago-suspenso` — Arquipélago Suspenso

Um ambiente vertical sem chão global: cinco ilhas em alturas diferentes, pontes incompletas, um farol, um bosque de cristais e planadores orbitais.

Demonstra:

- autoria de um mundo próprio com `:construtor-cena`;
- navegação vertical com `Q/E`;
- composição assimétrica;
- múltiplas alturas e plataformas;
- uso combinado de cubos, pirâmides e comportamentos.

## `galeria-do-monolito` — Galeria do Monólito

Um museu fechado e comprido, com piso, teto, paredes e pedestais. A peça principal usa `assets/modelos/monolito.obj`; quatro peças laterais usam `assets/modelos/cristal.obj`.

Demonstra:

- carregamento de mais de uma malha OBJ;
- reutilização de uma malha carregada em múltiplas entidades;
- mistura de arquitetura procedural com assets externos;
- `:fonte-malha` e entidades `:obj`.

## Criando seu próprio ambiente

Use a cena vazia em vez de herdar a demo:

```lisp
(load "examples/_bootstrap.lisp")

(defun minha-cena ()
  (limiar3d:preparar-cena-vazia)

  (limiar3d:configurar-ambiente
   :hora 16.0
   :ciclo-dia-noite-p nil
   :cor-ceu (limiar3d:v3 0.25 0.45 0.70))

  (limiar3d:configurar-camera
   :posicao (limiar3d:v3 0.0 3.0 12.0)
   :rotacao (limiar3d:v3 -8.0 0.0 0.0))

  (limiar3d:adicionar-entidade
   (limiar3d:criar-chao :nome "meu-chao")))

(limiar3d:iniciar :construtor-cena #'minha-cena)
```

O motor guarda esse construtor como a cena atual. Por isso `R` executa novamente `minha-cena`, e `X` volta à câmera registrada por `configurar-camera`.
