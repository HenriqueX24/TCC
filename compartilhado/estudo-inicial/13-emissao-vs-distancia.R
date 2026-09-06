library(dplyr)
library(lubridate)
library(ggplot2)
library(plotly)
library(tidyr)

# 1. Juntar dados
df_all <- data

# 2. Converter timestamp
df_all <- df_all %>%
  mutate(
    GPSTIMESTAMP = ymd_hms(GPSTIMESTAMP),
    VELOCITY_KMH = VELOCITY * 3.6
  )

# 3. Agrupar a cada 5 minutos POR LINHA
df_time <- df_all %>%
  mutate(time_bin = floor_date(GPSTIMESTAMP, unit = "5 minutes")) %>%
  group_by(LINE, time_bin) %>%
  summarise(
    emissao_media = mean(CO_2, na.rm = TRUE),
    co_medio = mean(CO, na.rm = TRUE),
    distancia_total = sum(DISTANCE, na.rm = TRUE),
    .groups = "drop"
  )

# 4. Normalizar por linha
df_time <- df_time %>%
  group_by(LINE) %>%
  mutate(
    emissao_norm = emissao_media / max(emissao_media, na.rm = TRUE),
    co_norm = co_medio / max(co_medio, na.rm = TRUE),
    distancia_norm = distancia_total / max(distancia_total, na.rm = TRUE)
  ) %>%
  ungroup()

# 5. Formato longo (agora com CO)
df_long <- df_time %>%
  select(LINE, time_bin, emissao_norm, co_norm, distancia_norm) %>%
  pivot_longer(
    cols = c(emissao_norm, co_norm, distancia_norm),
    names_to = "tipo",
    values_to = "valor"
  ) %>%
  mutate(
    tipo = case_when(
      tipo == "emissao_norm" ~ "CO2",
      tipo == "co_norm" ~ "CO",
      tipo == "distancia_norm" ~ "Distância"
    )
  )

# 6. Gráfico
p <- ggplot(df_long, aes(x = time_bin, y = valor, color = tipo)) +
  geom_line(size = 1) +
  facet_wrap(~ LINE, scales = "free_y") +
  theme_minimal() +
  labs(
    title = "Emissão (CO2), CO e Distância ao Longo do Dia por Linha",
    x = "Tempo",
    y = "Valor normalizado",
    color = "Métrica"
  )

# 7. Interativo
ggplotly(p)
