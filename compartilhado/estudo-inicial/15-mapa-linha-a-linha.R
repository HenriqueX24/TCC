# 1. PACOTES NECESSÁRIOS
# install.packages(c("leaflet", "dplyr", "lubridate", "ggplot2", "plotly", "geosphere", "htmlwidgets"))
library(leaflet)
library(dplyr)
library(lubridate)
library(ggplot2)
library(plotly)
library(geosphere)
library(htmlwidgets)

# ==============================================================================
# FASE 1: PREPARAÇÃO, LIMPEZA E CÁLCULO DE TRAJETÓRIA
# ==============================================================================

# Filtra o banco original (assumindo que se chama 'data') para as linhas 321 a 329
df_alvo <- subset(data, LINE %in% 321:329)
df_alvo$LINE <- as.factor(df_alvo$LINE)

# Converte o tempo e ordena cronologicamente
df_alvo <- df_alvo %>%
  mutate(TIMESTAMP_FORMATADO = ymd_hms(GPSTIMESTAMP)) %>%
  arrange(TIMESTAMP_FORMATADO)

# Remove veículos parados (velocidade máxima = 0)
max_vel_por_onibus <- aggregate(VELOCITY ~ BUSID, data = df_alvo, max, na.rm = TRUE)
onibus_ativos <- max_vel_por_onibus$BUSID[max_vel_por_onibus$VELOCITY > 0]
df_ativo <- subset(df_alvo, BUSID %in% onibus_ativos)

# Calcula o Ângulo de Movimento e define a Direção (Ida/Volta)
df_ativo <- df_ativo %>%
  arrange(BUSID, TIMESTAMP_FORMATADO) %>%
  group_by(BUSID) %>%
  mutate(
    PROX_LON = lead(LONGITUDE),
    PROX_LAT = lead(LATITUDE),
    ANGULO_BRUTO = bearing(cbind(LONGITUDE, LATITUDE), cbind(PROX_LON, PROX_LAT)),
    ANGULO = (ANGULO_BRUTO + 360) %% 360,
    DIRECAO = case_when(
      is.na(ANGULO) ~ "Sem Direção (Fim)",
      (ANGULO >= 315 | ANGULO < 45) ~ "Indo para o Norte",
      (ANGULO >= 45 & ANGULO < 135) ~ "Indo para o Leste",
      (ANGULO >= 135 & ANGULO < 225) ~ "Indo para o Sul",
      (ANGULO >= 225 & ANGULO < 315) ~ "Indo para o Oeste"
    )
  ) %>%
  mutate(DIRECAO = as.factor(DIRECAO)) %>%
  select(-PROX_LON, -PROX_LAT, -ANGULO_BRUTO) %>%
  ungroup()

# ==============================================================================
# FASE 2: MAPAS ESPACIAIS COM FILTRO DE DIREÇÃO (LEAFLET)
# ==============================================================================

# Cores fixas para cada direção (para o Leste ser sempre azul, Oeste vermelho, etc.)
paleta_direcao <- colorFactor(
  palette = c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#999999"), 
  domain = df_ativo$DIRECAO
)

lista_de_mapas <- list()

for (linha_atual in 321:329) {
  df_filtrado <- df_ativo %>% filter(LINE == linha_atual)
  
  if (nrow(df_filtrado) > 0) {
    direcoes_presentes <- as.character(unique(df_filtrado$DIRECAO))
    
    mapa <- leaflet(data = df_filtrado) %>%
      addTiles() %>% 
      addCircleMarkers(
        lng = ~LONGITUDE, lat = ~LATITUDE, 
        color = ~paleta_direcao(DIRECAO), 
        group = ~DIRECAO, # Permite o filtro interativo
        radius = 3, stroke = FALSE, fillOpacity = 0.7,    
        popup = ~paste("Linha:", LINE, "<br>Ônibus:", BUSID, 
                       "<br>Sentido:", DIRECAO, "<br>Vel:", VELOCITY, "km/h")
      ) %>%
      addLegend("bottomright", pal = paleta_direcao, values = ~DIRECAO, title = paste("Linha", linha_atual)) %>%
      addLayersControl(overlayGroups = direcoes_presentes, options = layersControlOptions(collapsed = FALSE))
    
    lista_de_mapas[[as.character(linha_atual)]] <- mapa
    
    # Exporta o mapa automaticamente
    saveWidget(mapa, file = paste0("mapa_linha_", linha_atual, ".html"), selfcontained = TRUE)
  }
}

