# Exemplos do Limiar 3D

Os exemplos são **cinco ambientes independentes**. Eles não chamam a cena de demonstração interna e depois adicionam objetos por cima: cada arquivo começa com `limiar3d:preparar-cena-vazia` e constrói seu próprio mundo, câmera, céu, gravidade e composição.

Execute pela raiz do repositório:

```sh
sbcl --load ~/quicklisp/setup.lisp --script scripts/run-example.lisp observatorio-do-alvorecer
```

Ambientes disponíveis:

- `observatorio-do-alvorecer` — **Observatório do Alvorecer**: praça aberta e clara, pilares, astrolábio interagível e marcadores orbitais;
- `deposito-de-impacto` — **Depósito de Impacto**: galpão industrial fechado, docas, carga empilhada e contêineres dinâmicos;
- `templo-do-eclipse` — **Templo do Eclipse**: altares suspensos no vazio, sigilos orbitais e leis que mudam gravidade e céu;
- `arquipelago-suspenso` — **Arquipélago Suspenso**: ilhas em níveis diferentes, pontes aéreas, farol, cristais e planadores;
- `galeria-do-monolito` — **Galeria do Monólito**: museu fechado com corredor, pedestais e duas malhas OBJ reais (`monolito.obj` e `cristal.obj`).

`R` reconstrói **o ambiente que está aberto**. `X` retorna à câmera inicial configurada por aquele ambiente.

Consulte [`../doc-ptbr/EXEMPLOS.md`](../doc-ptbr/EXEMPLOS.md) para detalhes.
