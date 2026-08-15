# Contribuindo com o Limiar 3D

O Limiar 3D valoriza legibilidade acima de abstração excessiva. O motor principal deve continuar pequeno o bastante para ser estudado como um único programa.

## Antes de enviar uma mudança

1. mantenha nomes e comentários do código-fonte em português do Brasil;
2. preserve `limiar3d.lisp` como o motor completo em um único arquivo;
3. prefira funções curtas e dados explícitos a hierarquias profundas;
4. atualize a documentação PT-BR e, quando possível, a equivalente em inglês;
5. execute `sbcl --load ~/quicklisp/setup.lisp --script run-tests.lisp`;
6. adicione um exemplo quando a funcionalidade for melhor entendida visualmente;
7. exemplos de ambiente devem começar com `preparar-cena-vazia`, definir câmera/ambiente próprios e não chamar `reiniciar-cena`; execute `bash scripts/check-examples.sh`.

## Escopo

São bem-vindas correções, novos exemplos, melhorias na API, carregadores simples, recursos de depuração e sistemas que reforcem a natureza hackeável do motor. Mudanças que transformem o projeto em uma abstração pesada ou ocultem completamente OpenGL atrás de muitas camadas devem ser justificadas com cuidado.
