library(ggplot2)

ggplot(df_all, aes(x = VELOCITY_KMH)) +
  geom_density() +
  theme_minimal() +
  labs(
    title = "Distribuição de Densidade da Velocidade",
    x = "Velocidade (km/h)",
    y = "Densidade"
  )