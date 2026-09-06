# Inferência de Rotas e Baldeação

Tema voltado à inferência de rotas e conexões entre linhas usando trajetórias realizadas.

## Problema

Dado um conjunto de trajetórias observadas, inferir quais rotas e conexões entre linhas são plausíveis. O GTFS deve ser usado apenas como gabarito de avaliação, depois que o algoritmo gerar sua própria inferência.

## Perguntas

- Como reconstruir rotas a partir das trajetórias realizadas?
- Como identificar proximidade, sobreposição ou cruzamento entre linhas?
- Como sugerir baldeações plausíveis entre uma origem e um destino?
- Como comparar a inferência com o GTFS sem usar o GTFS como entrada do algoritmo?
- Trajetórias sintéticas podem ampliar cenários de teste mantendo separação do gabarito?

## Entrada

- Trajetórias realizadas por ônibus.
- Bases limpas de `../compartilhado/`.
- GTFS somente na etapa final de validação.

## Saída Esperada

- Rotas inferidas a partir de GPS.
- Grafo inferido de linhas e conexões.
- Sugestões de baldeação.
- Comparação com o GTFS como gabarito.

## Códigos e Materiais

- `codigos/1Limpeza.R`: preparação de dados para trajetórias.
- `codigos/Realistic_Trajectory_Generation_using_Simple_PLMs.ipynb`: experimento com geração de trajetórias.
- `materiais/`: PDFs de apoio sobre geração de trajetórias.
- `palmto-gen/`: implementação e materiais do PaLMTo-Gen.
