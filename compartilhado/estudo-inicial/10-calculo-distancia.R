# 1. Cria a função matemática para calcular a distância entre coordenadas (em Km)
dist_haversine <- function(lon1, lat1, lon2, lat2) {
  rad <- pi / 180
  R <- 6371 # Raio médio da Terra em Km
  dlon <- (lon2 - lon1) * rad
  dlat <- (lat2 - lat1) * rad
  a <- sin(dlat/2)^2 + cos(lat1 * rad) * cos(lat2 * rad) * sin(dlon/2)^2
  c <- 2 * atan2(sqrt(a), sqrt(1 - a))
  return(R * c)
}

# 2. Descobre quais linhas de ônibus existem na base data_linha
linhas_unicas <- unique(data_linha$LINE[!is.na(data_linha$LINE)])

# 3. Prepara uma tabela vazia para guardar os resultados
resultados_dist <- data.frame(Linha = numeric(), Distancia_Km = numeric())

# 4. Calcula a distância sequencial para cada linha de ônibus
for (linha_atual in linhas_unicas) {
  # Filtra os dados usando a sua base 'data_linha'
  dados_linha <- subset(data_linha, LINE == linha_atual & !is.na(LATITUDE) & !is.na(LONGITUDE))
  
  if (nrow(dados_linha) > 1) {
    # Pega todos os pontos (exceto o último) como origem
    lon_origem <- dados_linha$LONGITUDE[-nrow(dados_linha)]
    lat_origem <- dados_linha$LATITUDE[-nrow(dados_linha)]
    
    # Pega todos os pontos (exceto o primeiro) como destino
    lon_destino <- dados_linha$LONGITUDE[-1]
    lat_destino <- dados_linha$LATITUDE[-1]
    
    # Aplica a fórmula e soma tudo
    dist_vetor <- dist_haversine(lon_origem, lat_origem, lon_destino, lat_destino)
    dist_total <- round(sum(dist_vetor, na.rm = TRUE), 2)
  } else {
    dist_total <- 0
  }
  
  # Salva o resultado
  resultados_dist <- rbind(resultados_dist, data.frame(Linha = linha_atual, Distancia_Km = dist_total))
}

# 5. Ordena a tabela para mostrar no topo os ônibus que rodaram mais
resultados_dist <- resultados_dist[order(-resultados_dist$Distancia_Km), ]

# 6. Abre a tabela de resultados limpa
View(resultados_dist)