# Cenas e persistência

O formato `.l3d` é uma S-expression legível. A intenção é que o estado salvo possa ser inspecionado por humanos e por ferramentas Lisp.


## Cena vazia versus demo interna

`reiniciar-cena` cria a demonstração oficial do motor. Para um ambiente próprio, use:

```lisp
(limiar3d:preparar-cena-vazia)
(limiar3d:configurar-ambiente ...)
(limiar3d:configurar-camera ...)
```

Isso evita que mundos diferentes compartilhem acidentalmente o mesmo chão, núcleo ou câmera. Os cinco exemplos do repositório seguem esse padrão desde a v0.2.6.

## Salvar

```lisp
(limiar3d:salvar-cena "mundo.l3d")
```

## Carregar

```lisp
(limiar3d:carregar-cena "mundo.l3d")
```

## Segurança do reader

O código desabilita `*read-eval*` nas leituras em que dados externos são interpretados. Arquivos de cena ainda devem ser tratados como dados de projeto e revisados quando vierem de fontes não confiáveis.

## O que é serializado

A cena armazena câmera, hora/configuração (incluindo céu fixo), e dados serializáveis das entidades. Closures de comportamento e callbacks arbitrários não podem ser reconstruídos automaticamente de forma portátil; portanto, lógica dinâmica deve ser reinstalada pelo construtor de cena ou pelo código do jogo depois do carregamento.

## Filosofia

O `.l3d` não pretende ser um formato universal. Ele existe para manter o fluxo de criação compatível com Lisp: estruturas de dados simples, imprimíveis e fáceis de transformar.
