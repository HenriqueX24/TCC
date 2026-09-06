# Trajetoria

Repositório organizado por escopos de pesquisa. As pastas `T1`, `T2` e `T3` representam temas, não uma ordem obrigatória de execução. Códigos e materiais compartilhados ficam em `compartilhado/`.

## Como Navegar

### `compartilhado/`

Base técnica comum para os temas.

Use esta pasta para dados, ETL, leitura de arquivos, limpeza inicial, referências geográficas e materiais que não pertencem a um único tema.

### `T1-congestionamentos/`

Tema sobre identificação de congestionamentos a partir de registros GPS, velocidade, horário, chuva e localização.

### `T2-pontos-finais-sentido/`

Tema sobre localização automática dos pontos finais das linhas e estimativa do sentido em que o ônibus está circulando.

Este é o escopo mais objetivo para os códigos de direção: antes de classificar ida/volta, é preciso inferir quais são os extremos prováveis da linha.

### `T3-inferencia-rotas-baldeacao/`

Tema sobre inferência de rotas e conexões entre linhas usando trajetórias realizadas.

O algoritmo deve usar apenas as trajetórias observadas. O GTFS deve ser usado depois como gabarito para comparar a rota inferida com a rota oficial, não como entrada da inferência.

### `temas/`

Texto acadêmico em LaTeX e artefatos de compilação.

### `tema.pptx`

Apresentação resumida do enunciado atual do trabalho.

## Escopos Atuais

| Escopo | Problema | Entrada principal | Saída esperada |
| --- | --- | --- | --- |
| Compartilhado | Preparar dados para análise | Parquet, RData, GPS, GeoJSON | Base limpa e reutilizável |
| T1 | Detectar regiões de baixa fluidez | GPS, velocidade, horário, chuva | Agrupamentos e mapas de congestionamento |
| T2 | Inferir terminais e ida/volta | Trajetórias realizadas por linha/veículo | Pontos finais prováveis e sentido estimado |
| T3 | Inferir conexões entre linhas | Trajetórias realizadas | Rotas/conexões inferidas, avaliadas depois com GTFS |

## Organização dos Códigos

Os códigos ficam próximos ao problema que resolvem:

- `compartilhado/codigos/`: leitura, busca, ETL e limpeza compartilhada.
- `T1-congestionamentos/codigos/`: análise de congestionamento.
- `T2-pontos-finais-sentido/codigos/`: classificação de sentido, cálculo vetorial, filtragem por rota/veículo.
- `T3-inferencia-rotas-baldeacao/codigos/`: limpeza e experimentos ligados a geração/inferência de trajetórias.

## O Que Foi Retirado do Escopo

Foram removidos da organização principal os códigos de métodos que não sustentam a direção atual do trabalho, especialmente códigos antigos sem escopo claro e experimentos já concluídos ou pouco relevantes.

## Próximos Passos Recomendados

1. Consolidar o ETL em `compartilhado/`.
2. Priorizar `T2-pontos-finais-sentido/`, porque ele resolve uma necessidade objetiva da base.
3. Definir formalmente o algoritmo de `T3-inferencia-rotas-baldeacao/`.
4. Usar GTFS apenas na etapa de avaliação, como gabarito.
5. Atualizar o texto em `temas/main.tex` para refletir esta nova organização.
