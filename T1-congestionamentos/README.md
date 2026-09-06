# Congestionamentos

Tema voltado à identificação de regiões e períodos de baixa fluidez no transporte por ônibus.

## Problema

Detectar padrões compatíveis com congestionamento a partir de registros de GPS, velocidade, horário, chuva e localização.

## Perguntas

- Onde aparecem concentrações recorrentes de baixa velocidade?
- Esses agrupamentos variam por horário, região ou chuva?
- Como diferenciar congestionamento recorrente de evento pontual?

## Entrada

- Base limpa produzida em `../compartilhado/`.
- Campos esperados: latitude, longitude, velocidade, timestamp, chuva e região.

## Saída Esperada

- Agrupamentos de pontos com baixa velocidade.
- Mapas e estatísticas por região.
- Métrica preliminar de severidade.

## Códigos

- `codigos/analise-congestionamento.R`: análise com DBSCAN e visualizações.
