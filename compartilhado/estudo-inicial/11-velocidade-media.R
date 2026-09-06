library(dplyr)
library(lubridate)
library(ggplot2)
library(plotly)

# 1. Juntar dados
df_all <- bind_rows(data)

# 2. Converter timestamp + velocidade para km/h
df_all <- df_all %>%
  mutate(
    GPSTIMESTAMP = ymd_hms(GPSTIMESTAMP),
    VELOCITY_KMH = VELOCITY * 3.6
  )

# 3. Média a cada 5 minutos
df_5min <- df_all %>%
  mutate(time_bin = floor_date(GPSTIMESTAMP, unit = "5 minutes")) %>%
  group_by(LINE, time_bin) %>%
  summarise(vel_media = mean(VELOCITY_KMH, na.rm = TRUE), .groups = "drop")

# 4. Gráfico
p <- ggplot(df_5min, aes(x = time_bin, y = vel_media, color = LINE)) +
  geom_line() +
  theme_minimal() +
  labs(
    title = "Velocidade média (km/h) a cada 5 minutos",
    x = "Tempo",
    y = "Velocidade média (km/h)"
  )

# 5. Interativo
ggplotly(p)
