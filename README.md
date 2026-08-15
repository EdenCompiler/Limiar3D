# Limiar 3D — Single-file 3D engine in Common Lisp

> **Languages / Idiomas:** [English](#english) · [Português do Brasil](#português-do-brasil)

---

# English

Limiar 3D is a small, readable 3D game engine written in Common Lisp. Its defining constraint is intentional: **the complete engine lives in one `limiar3d.lisp` file**. The surrounding repository adds ASDF packaging, examples, tests, scripts, CI, assets, and documentation without splitting the engine itself into a maze of modules.

**Current release: 0.2.6**

![Limiar 3D](https://img.shields.io/badge/Limiar%203D-0.2.6-blue)
![Common Lisp](https://img.shields.io/badge/Common%20Lisp-SBCL-informational)
![OpenGL](https://img.shields.io/badge/renderer-OpenGL-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

## What Limiar 3D is

Limiar 3D is aimed at experiments, small games, teaching, prototypes, and projects where changing the world from the Lisp REPL is part of the design. It deliberately uses classic OpenGL through `cl-opengl`/`cl-glut` so that the rendering path stays visible and understandable.

It is **not** trying to compete with Godot, Unity, Unreal, or a modern production renderer.

## Highlights

- complete engine in one readable Common Lisp source file;
- first-person 3D camera with continuous frame-based input;
- `W/S` movement derived from the exact camera view direction;
- click-and-drag mouse look; short left click interacts;
- triangle meshes, cubes, pyramids, floor geometry, and basic OBJ loading;
- entities with tags, metadata, velocities, and Lisp behaviors;
- simple gravity, dynamic/static bodies, friction, restitution, and AABB collision;
- camera raycast and interactable objects;
- global rule system expressed as Lisp condition/action closures;
- day/night cycle and simple directional CPU lighting;
- human-readable `.l3d` scene persistence based on S-expressions;
- live REPL experimentation;
- ASDF system, no-window tests, five deliberately distinct runnable environments, and GitHub Actions CI;
- documentation in English and Brazilian Portuguese.

## Installation

System packages on Debian/Ubuntu:

```sh
sudo apt install sbcl freeglut3-dev libgl1-mesa-dev
```

Install Quicklisp, clone this repository, and either put it where ASDF can find it or load the convenience file from the checkout:

```lisp
(load #P"quickstart.lisp")
(limiar3d:iniciar)
```

The explicit ASDF route is also supported:

```lisp
(asdf:load-asd #P"/path/to/limiar3d/limiar3d.asd")
(ql:quickload :limiar3d)
(limiar3d:iniciar)
```

## Controls

| Input | Action |
| --- | --- |
| Left click + drag | Look around |
| Short left click | Interact with targeted entity |
| `W` / `S` | Move along the camera's exact forward/back direction |
| `A` / `D` | Strafe along the camera-local right axis |
| `Q` / `E` | Move down/up |
| Shift | Turbo |
| Arrow keys or `IJKL` | Keyboard look |
| Right click or `C` | Launch a physics cube |
| `F` | Interact |
| `[` / `]` | Change FOV |
| `T` | Solid/wireframe |
| `G` | Grid |
| `O` | Axes |
| `N` | Day/night cycle |
| `P` | Pause |
| `B` | Print engine state |
| `R` | Rebuild the currently loaded environment |
| `X` | Reset camera |
| `H` | Help |
| Esc | Exit |

## Quick tour

Create a physics cube:

```lisp
(limiar3d:adicionar-entidade
 (limiar3d:criar-cubo
  :nome "caixa"
  :posicao (limiar3d:v3 0.0 8.0 -4.0)
  :fisico-p t
  :dinamico-p t))
```

Add a rule to reality:

```lisp
(limiar3d:adicionar-regra
 (limiar3d:criar-regra
  "gravidade-da-noite"
  (lambda () (> limiar3d:*hora-do-dia* 18.0))
  (lambda ()
    (setf (limiar3d::configuracao-motor-gravidade limiar3d:*configuracao*)
          4.0))
  :uma-vez-p t))
```

Save the current world:

```lisp
(limiar3d:salvar-cena "mundo.l3d")
```

## Examples

Run from the repository root:

```sh
sbcl --load ~/quicklisp/setup.lisp --script scripts/run-example.lisp observatorio-do-alvorecer
sbcl --load ~/quicklisp/setup.lisp --script scripts/run-example.lisp deposito-de-impacto
sbcl --load ~/quicklisp/setup.lisp --script scripts/run-example.lisp templo-do-eclipse
sbcl --load ~/quicklisp/setup.lisp --script scripts/run-example.lisp arquipelago-suspenso
sbcl --load ~/quicklisp/setup.lisp --script scripts/run-example.lisp galeria-do-monolito
```

These are intentionally different worlds rather than parameter variations of one demo:

| Example | Environment | Character |
| --- | --- | --- |
| `observatorio-do-alvorecer` | **Dawn Observatory** | bright open plaza, interactable astrolabe, orbiting markers |
| `deposito-de-impacto` | **Impact Warehouse** | enclosed industrial hall, loading docks, stacked and falling cargo |
| `templo-do-eclipse` | **Eclipse Temple** | floating altars, orbital sigils, runtime laws that alter gravity and sky |
| `arquipelago-suspenso` | **Floating Archipelago** | no global floor, islands at several heights, bridges, lighthouse and gliders |
| `galeria-do-monolito` | **Monolith Gallery** | enclosed museum mixing procedural architecture with two OBJ meshes |

Every custom example starts from `preparar-cena-vazia`; none inherits the built-in demo geometry.

## Tests

The test suite does not create an OpenGL window:

```sh
sbcl --load ~/quicklisp/setup.lisp --script run-tests.lisp
```

It checks vector math, camera-forward consistency, AABB collision, entity metadata, one-shot global rules, empty-scene preparation, fixed-sky configuration, and per-environment camera reset.

## Repository layout

```text
limiar3d.lisp           complete engine
limiar3d.asd            ASDF system definition
quickstart.lisp         checkout-friendly loader
run-tests.lisp          test entry point
examples/               runnable demos
assets/                 small example assets
tests/                  no-window tests
doc-en/                 English documentation
doc-ptbr/               Brazilian Portuguese documentation
scripts/                 shell/PowerShell/example runners
.github/workflows/      CI
```

## Documentation

- [Architecture](doc-en/ARCHITECTURE.md)
- [API guide](doc-en/API.md)
- [Building and installation](doc-en/BUILDING.md)
- [Examples](doc-en/EXAMPLES.md)
- [Controls and camera model](doc-en/CONTROLS.md)
- [Scenes and persistence](doc-en/SCENES-AND-PERSISTENCE.md)
- [Metaprogramming and world rules](doc-en/METAPROGRAMMING.md)
- [Limitations and roadmap](doc-en/LIMITATIONS-AND-ROADMAP.md)

## Design rule

The repository may grow. The engine should remain readable.

That means new tooling, documentation, examples, tests, and assets can live around `limiar3d.lisp`, but the core project identity remains a single-file engine whose major systems can be followed from top to bottom.

## License

MIT. See [LICENSE](LICENSE).

---

# Português do Brasil

Limiar 3D é um pequeno motor de jogos 3D escrito em Common Lisp com uma restrição intencional: **o motor completo vive em um único arquivo `limiar3d.lisp`**. O repositório ao redor adiciona empacotamento ASDF, exemplos, testes, scripts, CI, assets e documentação sem transformar o núcleo em dezenas de módulos difíceis de acompanhar.

**Versão atual: 0.2.6**

## O que é o Limiar 3D

O projeto foi pensado para experimentos, jogos pequenos, ensino, protótipos e jogos em que alterar o mundo pelo REPL Lisp pode fazer parte da própria mecânica. O renderer usa OpenGL clássico por `cl-opengl`/`cl-glut` de propósito: a prioridade é tornar o caminho entre entidade, transformação, câmera e triângulo visível ao leitor.

Ele **não** tenta competir com Godot, Unity, Unreal ou um renderer moderno de produção.

## Destaques

- motor completo em um único arquivo Common Lisp legível;
- câmera 3D em primeira pessoa com entrada contínua por frame;
- `W/S` derivados da direção visual exata da câmera;
- mouse-look por clique e arraste; clique curto interage;
- malhas triangulares, cubos, pirâmides, chão e carregador OBJ básico;
- entidades com tags, metadados, velocidades e comportamentos Lisp;
- gravidade, corpos estáticos/dinâmicos, atrito, restituição e colisão AABB simples;
- raycast da câmera e objetos interagíveis;
- sistema de regras globais como closures Lisp de condição/ação;
- ciclo dia/noite e iluminação direcional simples calculada na CPU;
- cenas `.l3d` legíveis baseadas em S-expressions;
- experimentação ao vivo pelo REPL;
- sistema ASDF, testes sem janela, cinco ambientes executáveis deliberadamente distintos e CI;
- documentação em português do Brasil e inglês.

## Instalação

No Debian/Ubuntu:

```sh
sudo apt install sbcl freeglut3-dev libgl1-mesa-dev
```

Com Quicklisp instalado, clone o repositório e carregue:

```lisp
(load #P"quickstart.lisp")
(limiar3d:iniciar)
```

Ou use ASDF explicitamente:

```lisp
(asdf:load-asd #P"/caminho/para/limiar3d/limiar3d.asd")
(ql:quickload :limiar3d)
(limiar3d:iniciar)
```

## Controles

| Entrada | Ação |
| --- | --- |
| Clique esquerdo + arraste | Olhar ao redor |
| Clique esquerdo curto | Interagir com a entidade na mira |
| `W` / `S` | Avançar/recuar pela direção visual exata da câmera |
| `A` / `D` | Strafe pelo eixo direito local da câmera |
| `Q` / `E` | Descer/subir |
| Shift | Turbo |
| Setas ou `IJKL` | Olhar pelo teclado |
| Clique direito ou `C` | Lançar cubo físico |
| `F` | Interagir |
| `[` / `]` | Alterar FOV |
| `T` | Sólido/aramado |
| `G` | Grade |
| `O` | Eixos |
| `N` | Ciclo dia/noite |
| `P` | Pausar |
| `B` | Mostrar estado no terminal |
| `R` | Reconstruir o ambiente atualmente carregado |
| `X` | Restaurar câmera |
| `H` | Ajuda |
| Esc | Sair |

## Tour rápido

Crie um cubo físico:

```lisp
(limiar3d:adicionar-entidade
 (limiar3d:criar-cubo
  :nome "caixa"
  :posicao (limiar3d:v3 0.0 8.0 -4.0)
  :fisico-p t
  :dinamico-p t))
```

Adicione uma lei ao mundo:

```lisp
(limiar3d:adicionar-regra
 (limiar3d:criar-regra
  "gravidade-da-noite"
  (lambda () (> limiar3d:*hora-do-dia* 18.0))
  (lambda ()
    (setf (limiar3d::configuracao-motor-gravidade limiar3d:*configuracao*)
          4.0))
  :uma-vez-p t))
```

Salve o mundo atual:

```lisp
(limiar3d:salvar-cena "mundo.l3d")
```

## Exemplos

Na raiz do repositório:

```sh
sbcl --load ~/quicklisp/setup.lisp --script scripts/run-example.lisp observatorio-do-alvorecer
sbcl --load ~/quicklisp/setup.lisp --script scripts/run-example.lisp deposito-de-impacto
sbcl --load ~/quicklisp/setup.lisp --script scripts/run-example.lisp templo-do-eclipse
sbcl --load ~/quicklisp/setup.lisp --script scripts/run-example.lisp arquipelago-suspenso
sbcl --load ~/quicklisp/setup.lisp --script scripts/run-example.lisp galeria-do-monolito
```

Os exemplos são mundos propositalmente diferentes, não variações de parâmetros da mesma demo:

| Exemplo | Ambiente | Identidade |
| --- | --- | --- |
| `observatorio-do-alvorecer` | **Observatório do Alvorecer** | praça aberta, astrolábio interagível e marcadores orbitais |
| `deposito-de-impacto` | **Depósito de Impacto** | galpão industrial fechado, docas e carga empilhada/caindo |
| `templo-do-eclipse` | **Templo do Eclipse** | altares suspensos, sigilos orbitais e leis que alteram gravidade e céu |
| `arquipelago-suspenso` | **Arquipélago Suspenso** | sem chão global, ilhas em várias alturas, pontes, farol e planadores |
| `galeria-do-monolito` | **Galeria do Monólito** | museu fechado misturando arquitetura procedural e duas malhas OBJ |

Cada exemplo customizado começa em `preparar-cena-vazia`; nenhum herda a geometria da demo interna.

## Testes

A suíte não abre uma janela OpenGL:

```sh
sbcl --load ~/quicklisp/setup.lisp --script run-tests.lisp
```

Ela cobre matemática vetorial, consistência da direção da câmera, AABB, metadados, regras globais, preparação de cena vazia, céu fixo e reset de câmera por ambiente.

## Estrutura do repositório

```text
limiar3d.lisp           motor completo
limiar3d.asd            definição ASDF
quickstart.lisp         loader para checkout local
run-tests.lisp          entrada dos testes
examples/               demos executáveis
assets/                 pequenos assets de exemplo
tests/                  testes sem janela
doc-en/                 documentação em inglês
doc-ptbr/               documentação em português
scripts/                 runners shell/PowerShell/Lisp
.github/workflows/      CI
```

## Documentação

- [Arquitetura](doc-ptbr/ARQUITETURA.md)
- [Guia da API](doc-ptbr/API.md)
- [Compilação e instalação](doc-ptbr/COMPILACAO.md)
- [Exemplos](doc-ptbr/EXEMPLOS.md)
- [Controles e câmera](doc-ptbr/CONTROLES.md)
- [Cenas e persistência](doc-ptbr/CENAS-E-PERSISTENCIA.md)
- [Metaprogramação e regras do mundo](doc-ptbr/METAPROGRAMACAO.md)
- [Limitações e roadmap](doc-ptbr/LIMITACOES-E-ROADMAP.md)

## Regra de design

O repositório pode crescer. O motor deve continuar legível.

Ferramentas, documentação, exemplos, testes e assets podem crescer ao redor de `limiar3d.lisp`, mas a identidade do projeto continua sendo um motor single-file cujos sistemas principais podem ser estudados de cima a baixo.

## Licença

MIT. Consulte [LICENSE](LICENSE).
