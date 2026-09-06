 # install.packages("leaflet")

library(leaflet)


paleta_cores <- colorFactor(palette = "Set1", domain = df_ativo$LINE)

# Monta o mapa 
mapa_ruas <- leaflet(data = df_ativo) %>%
  addTiles() %>% # puxa o mapa da cidade
  addCircleMarkers(
    lng = ~LONGITUDE, 
    lat = ~LATITUDE, 
    color = ~paleta_cores(LINE), 
    radius = 3,           
    stroke = FALSE,
    fillOpacity = 0.6,    
    popup = ~paste("Linha:", LINE, "<br>Velocidade:", VELOCITY, "km/h")
  ) %>%
  addLegend("bottomright", pal = paleta_cores, values = ~LINE, title = "Linhas de Ônibus")
