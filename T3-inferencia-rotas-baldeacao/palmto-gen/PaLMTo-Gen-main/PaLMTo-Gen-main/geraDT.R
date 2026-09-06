library(dplyr)
library(jsonlite)
library(reticulate) # Pacote ponte para usar o Python dentro do R

# 1. Moldamos a tabela do jeito exato que o PaLMTo-Gen exige
df_perfeito <- df_arrays %>%
  rowwise() %>%
  mutate(
    # fromJSON transforma a sua string "[[x,y]]" em uma lista/matriz real
    geometry = list(fromJSON(COORDENADAS_ARRAY))
  ) %>%
  ungroup() %>%
  # Renomeamos as colunas. O modelo exige 'geometry' e geralmente usa 'trip_id'
  select(trip_id = BUSID, geometry)

# 2. Chamamos o Pandas pelo R para salvar o Pickle
pd <- import("pandas")
pd$to_pickle(r_to_py(df_perfeito), "rotas_agrupadas.pkl")

print("Pronto! Arquivo rotas_agrupadas.pkl gerado com sucesso!")