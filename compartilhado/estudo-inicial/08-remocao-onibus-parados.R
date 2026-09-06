linhas_alvo <- c(321, 322, 323, 324, 325, 326, 327, 328, 329)
df_alvo <- subset(data, LINE %in% linhas_alvo)

df_alvo$LINE <- as.factor(df_alvo$LINE)

max_vel_por_onibus <- aggregate(VELOCITY ~ BUSID, data = df_alvo, max, na.rm = TRUE)

onibus_ativos <- max_vel_por_onibus$BUSID[max_vel_por_onibus$VELOCITY > 0]
df_ativo <- subset(df_alvo, BUSID %in% onibus_ativos)
