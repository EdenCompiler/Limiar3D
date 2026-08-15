#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

examples=(
  examples/observatorio-do-alvorecer.lisp
  examples/deposito-de-impacto.lisp
  examples/templo-do-eclipse.lisp
  examples/arquipelago-suspenso.lisp
  examples/galeria-do-monolito.lisp
)

legacy=(
  examples/demo-basico.lisp
  examples/fisica.lisp
  examples/regras-metafisicas.lisp
  examples/cena-personalizada.lisp
  examples/obj.lisp
)

for file in "${examples[@]}"; do
  [[ -f "$file" ]] || {
    echo "ERRO: exemplo oficial ausente: $file" >&2
    exit 1
  }

  grep -q 'limiar3d:preparar-cena-vazia' "$file" || {
    echo "ERRO: $file nao comeca de uma cena vazia." >&2
    exit 1
  }

  if grep -q 'limiar3d:reiniciar-cena' "$file"; then
    echo "ERRO: $file herda a demo interna via reiniciar-cena." >&2
    exit 1
  fi

  grep -q 'limiar3d:configurar-ambiente' "$file" || {
    echo "ERRO: $file nao define seu proprio ambiente." >&2
    exit 1
  }

  grep -q 'limiar3d:configurar-camera' "$file" || {
    echo "ERRO: $file nao define sua propria camera inicial." >&2
    exit 1
  }
done

# Os nomes antigos nao devem continuar como arquivos oficiais; apenas o runner os aceita como aliases.
for file in "${legacy[@]}"; do
  if [[ -e "$file" ]]; then
    echo "ERRO: arquivo legado ainda existe: $file" >&2
    exit 1
  fi
done

# Cada exemplo deve anunciar uma identidade de ambiente diferente.
mapfile -t nomes < <(grep -h '\[ambiente\]' "${examples[@]}" | sort -u)
if [[ "${#nomes[@]}" -ne "${#examples[@]}" ]]; then
  echo "ERRO: os exemplos nao possuem cinco identidades de ambiente unicas." >&2
  printf '%s\n' "${nomes[@]}" >&2
  exit 1
fi

[[ -f assets/modelos/monolito.obj ]]
[[ -f assets/modelos/cristal.obj ]]

echo "OK: cinco exemplos com nomes proprios e ambientes independentes verificados."
