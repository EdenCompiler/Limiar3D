# Limitações e roadmap

## Limitações atuais

- pipeline fixo do OpenGL e immediate mode;
- sem shaders programáveis no renderer padrão;
- sem texturas/UVs/MTL no loader OBJ;
- iluminação simples por face na CPU;
- física AABB sem rotação real do collider;
- sem animação esquelética;
- sem áudio;
- sem GUI/editor visual;
- sem scene graph hierárquico;
- sem empacotamento oficial de executável;
- não é otimizado para milhares de entidades.

## Próximas direções naturais

1. texturas e UVs mantendo a API pequena;
2. HUD/debug overlay;
3. gatilhos e volumes de evento;
4. partículas simples;
5. áudio opcional;
6. console Lisp dentro da janela;
7. prefabs como S-expressions;
8. renderer moderno opcional sem remover o renderer didático;
9. sistema explícito de “conhecimento” capaz de revelar/alterar regras do mundo.

## Regra para novas features

Uma funcionalidade deve melhorar a capacidade de construir jogos sem destruir a possibilidade de entender o motor lendo `limiar3d.lisp` do começo ao fim.
