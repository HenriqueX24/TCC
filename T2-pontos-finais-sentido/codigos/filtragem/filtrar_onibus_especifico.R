library(dplyr)

# 1. Extrai o dataframe completo da linha 329 de dentro da lista
df_329 <- listas_por_linha[["329"]]

# 2. Descobre os IDs dos ônibus disponíveis na linha 329 para você escolher um
ids_disponiveis <- unique(df_329$BUSID)
print(ids_disponiveis)

# 3. Isola um único ônibus para o seu teste
# Substitua "COLOQUE_O_ID_AQUI" por um dos IDs reais que o comando acima mostrar (ex: "B28540")
onibus_escolhido <- df_329 %>%
  filter(BUSID == "B28629")
