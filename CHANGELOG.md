# Changelog

Todas as mudancas relevantes do Limiar 3D sao registradas aqui.

## 0.2.7

- Renomeia os exemplos oficiais para nomes proprios que correspondem aos mundos apresentados.
- `observatorio-do-alvorecer` substitui o antigo `demo-basico`.
- `deposito-de-impacto` substitui o antigo `fisica`.
- `templo-do-eclipse` substitui o antigo `regras-metafisicas`.
- `arquipelago-suspenso` substitui o antigo `cena-personalizada`.
- `galeria-do-monolito` substitui o antigo `obj`.
- O runner conserva os cinco nomes antigos como aliases de compatibilidade.
- Arquivos, README, documentacao e validacao de CI agora usam apenas os nomes oficiais.

## 0.2.6

- Refaz todos os exemplos como ambientes independentes, construidos a partir de uma cena vazia.
- `observatorio-do-alvorecer` agora e o **Observatorio do Alvorecer**, uma praca aberta com astrolabio interagivel e marcadores orbitais.
- `deposito-de-impacto` agora e o **Deposito de Impacto**, um galpao industrial fechado com docas, carga empilhada e contenedores dinamicos.
- `templo-do-eclipse` agora e o **Templo do Eclipse**, formado por altares suspensos, sigilos orbitais e leis que alteram gravidade e ceu durante a execucao.
- `arquipelago-suspenso` agora e o **Arquipelago Suspenso**, sem piso global, com ilhas em alturas diferentes, pontes, farol e planadores.
- `obj` agora e a **Galeria do Monolito**, um museu fechado que usa `monolito.obj` e o novo `cristal.obj`.
- Adiciona `preparar-cena-vazia`, `configurar-camera` e `configurar-ambiente` como API publica para autoria de ambientes.
- `R` reconstrói o exemplo atual em vez de substituir a cena pela demo interna.
- `X` retorna para a camera inicial definida pelo ambiente atual.
- Ceu fixo e camera inicial de ambiente passam a sobreviver ao fluxo de persistencia onde aplicavel.
- CI adiciona `scripts/check-examples.sh` para impedir regressao para exemplos que herdam a mesma cena-base.

## 0.2.5

- Corrige `SB-EXT:DEFCONSTANT-UNEQL` no SBCL ao compilar/carregar o motor via ASDF.
- `+NOME-MOTOR+` e `+VERSAO-MOTOR+` agora usam uma definicao de constante segura para valores nao-EQL, como strings.
- `quickstart.lisp` passa a carregar apenas as dependencias pelo Quicklisp e sempre usa o `limiar3d.asd` do checkout atual para o motor.
- `run-tests.lisp` usa o mesmo fluxo de dependencias do quickstart.
- O fluxo documentado `sbcl --load ~/quicklisp/setup.lisp --script scripts/run-example.lisp <exemplo>` volta a ser compativel com SBCL estrito.

## 0.2.4

- unificou a direcao visual da camera, raycast e movimento `W/S` usando a mesma transformacao camera-local -> mundo;
- corrigiu o desalinhamento entre a ordem de rotacao usada na view OpenGL e a formula de movimento;
- manteve suavizacao na velocidade escalar, mas tornou a direcao de movimento imediatamente responsiva a rotacao da camera;
- adicionou estrutura oficial de repositorio, sistema ASDF, exemplos, testes, CI e documentacao bilingue.

## 0.2.3

- fez `W/S` seguirem yaw e pitch da camera;
- fez `A/D` usarem o eixo lateral local da camera;
- normalizou movimento diagonal.

## 0.2.2

- substituiu mouse-look passivo por clique-e-arraste;
- clique esquerdo curto continua interagindo;
- clique direito lanca cubos fisicos.

## 0.2.1

- adicionou entrada continua por frame;
- adicionou aceleracao, frenagem e turbo com Shift;
- evitou repeticao involuntaria de toggles pelo auto-repeat do sistema operacional.

## 0.2.0

- introduziu a identidade Limiar 3D;
- adicionou fisica simples, AABB, raycast, interacao, regras, comportamentos, ciclo dia/noite, primitivas e cenas `.l3d`;
- preservou o motor inteiro em um unico arquivo Common Lisp legivel.
