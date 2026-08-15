# Metaprogramação e regras do mundo

O Limiar 3D foi desenhado para tornar pequena a distância entre “estado do jogo” e “programa que define o jogo”.

## Comportamentos como closures

```lisp
(limiar3d:adicionar-comportamento
 entidade
 (lambda (e delta)
   ;; altere E usando DELTA
   ))
```

A closure pode capturar estado lexical. Isso permite criar órbitas, máquinas de estado, efeitos temporários ou regras locais sem introduzir classes novas.

## Regras globais

```lisp
(limiar3d:criar-regra
 "nome"
 (lambda () condicao)
 (lambda () acao)
 :uma-vez-p t)
```

A ação pode alterar gravidade, cores, entidades, hora, metadados ou qualquer outro estado acessível.

## REPL como ferramenta de jogo

Como o estado principal é exportado, é possível inspecionar e mudar o mundo enquanto ele roda. Em um projeto convencional isso é apenas uma ferramenta de desenvolvimento; em um jogo de metaconhecimento, pode virar uma mecânica deliberada.

## Limite recomendado

Não transforme todo estado em variável global apenas porque Lisp permite. Entidades, regras e closures devem continuar sendo a unidade normal de organização. O estado exportado existe para experimentação e ferramentas.
