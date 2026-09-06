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