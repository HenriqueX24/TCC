library(dplyr)
library(lubridate)
library(reticulate)

# =========================================================
# 1. CONFIGURAÇÕES INICIAIS (SUAS ESCOLHAS)
# =========================================================
# Substitua 'data' pelo nome do banco que quer utilizar
df_bruto <- data

linha_desejada <- 328
limite_minutos <- 3

# =========================================================
# 2. PRIMEIRA LIMPA: FILTRAR A LINHA E PREPARAR O TEMPO
# =========================================================
df_linha <- df_bruto %>%
  # Pega apenas a linha escolhida
  filter(LINE == linha_desejada) %>%
  # Garante que o timestamp é entendido como tempo matemático pelo R
  mutate(GPSTIMESTAMP = ymd_hms(GPSTIMESTAMP))

print(paste("Total de registros encontrados para a linha", linha_desejada, ":", nrow(df_linha)))

# =========================================================
# 3. SEGUNDA LIMPA: CORTAR OS PULOS (TRAJETOS VOADORES)
# =========================================================
df_sem_pulos <- df_linha %>%
  # Ordena pelo ônibus e pelo tempo para a conta fazer sentido
  arrange(BUSID, GPSTIMESTAMP) %>%
  group_by(BUSID) %>%
  mutate(
    # Calcula os minutos entre um ponto de GPS e o anterior
    tempo_sem_sinal = as.numeric(difftime(GPSTIMESTAMP, lag(GPSTIMESTAMP), units = "mins")),
    tempo_sem_sinal = coalesce(tempo_sem_sinal, 0),
    
    # Se o GPS apagou por mais de 3 minutos, aciona o alarme
    alarme_pulo = if_else(tempo_sem_sinal > limite_minutos, 1, 0),
    
    # Cria o ID da sub-viagem somando os alarmes
    sub_viagem_id = cumsum(alarme_pulo)
  ) %>%
  # Cria o trip_id final (Ex: B10098_0, B10098_1)
  mutate(trip_id = paste0(BUSID, "_", sub_viagem_id)) %>%
  ungroup()

print(paste("Total de quebras de trajeto criadas por falta de sinal:", sum(df_sem_pulos$alarme_pulo)))

# =========================================================
# 4. MOLDAR PARA O PYTHON (PaLMTo-Gen) E EXPORTAR
# =========================================================
df_perfeito <- df_sem_pulos %>%
  group_by(trip_id) %>%
  summarise(
    # Junta as coordenadas em pares [lon, lat] para cada trajeto
    geometry = list(Map(function(lon, lat) c(lon, lat), LONGITUDE, LATITUDE))
  ) %>%
  ungroup()

# Exporta usando um nome dinâmico para você não sobrescrever arquivos sem querer
nome_arquivo <- paste0("rotas_linha_", linha_desejada, "_sem_pulos.pkl")

pd <- import("pandas")
pd$to_pickle(r_to_py(df_perfeito), nome_arquivo)

print(paste("Sucesso! Arquivo", nome_arquivo, "gerado e pronto para o modelo!"))