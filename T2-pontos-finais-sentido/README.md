# Pontos Finais e Sentido

Tema voltado à localização dos pontos finais de linhas de ônibus e à estimativa do sentido em que cada veículo está circulando.

## Problema

Muitas bases de GPS indicam a linha e o veículo, mas não informam claramente se o ônibus está em ida ou volta. Para estimar o sentido, primeiro é necessário localizar os extremos prováveis da linha.

## Perguntas

- Como identificar automaticamente os pontos finais de uma linha usando apenas trajetórias realizadas?
- Como estimar ida ou volta a partir desses pontos finais?
- Como lidar com trajetos incompletos, garagens, sobreposição de trechos e mudanças de linha?

## Entrada

- Trajetórias realizadas por linha e veículo.
- Base limpa de `../compartilhado/`.
- GeoJSON de apoio, quando necessário.

## Saída Esperada

- Pontos finais prováveis por linha.
- Segmentos classificados por sentido.
- Visualizações de validação das trajetórias classificadas.

## Códigos

- `codigos/classify.py`: fluxo principal de classificação.
- `codigos/produto-escalar.py`: estimativa por direção vetorial.
- `codigos/cumsum.py`: uso de soma acumulada.
- `codigos/cumsum-tendencia.py`: soma acumulada com tendência.
- `codigos/read-data.R`: leitura de dados para o tema.
- `codigos/filtragem/`: busca e filtragem por rota ou veículo.
