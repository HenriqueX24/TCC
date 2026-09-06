# Compartilhado

Esta pasta contém a infraestrutura compartilhada pelos subtemas de mobilidade urbana.

## Escopo

- Buscar e ler dados de mobilidade.
- Preparar arquivos Parquet/RData.
- Padronizar campos de GPS, tempo, linha, veículo e velocidade.
- Guardar bases auxiliares, como GeoJSON e arquivos serializados.
- Reunir referências usadas por mais de um tema.

## Códigos

- `codigos/BuscaDados.R`: busca/carregamento de dados.
- `codigos/Novo_modelo_limpeza.R`: limpeza principal.
- `codigos/read-parquet.R`: leitura de Parquet em R.
- `codigos/read-parquet.py`: leitura de Parquet em Python.
- `codigos/documentacao-etl.txt`: notas do fluxo de ETL.

## Dados e Apoio

- `dados-apoio/geojson/`: arquivos geográficos.
- `dados-apoio/pkl/`: arquivos serializados usados como apoio.
- `estudo-inicial/`: material exploratório inicial.
- `referencias/`: documentos externos usados como referência.
