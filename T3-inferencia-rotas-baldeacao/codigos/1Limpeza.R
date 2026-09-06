library(dplyr)
library(lubridate)
library(reticulate)

# =========================================================
# 1. CONFIGURAÇÕES INICIAIS (SUAS ESCOLHAS)
# =========================================================
# Substitua 'data' pelo nome do banco que quer utilizar
df_bruto <- data

# CORREÇÃO: Usar c() para criar um vetor com as múltiplas linhas
linhas_desejadas <- c(328, 913, 634)
limite_minutos <- 3

# =========================================================
# 2. PRIMEIRA LIMPA: FILTRAR AS LINHAS E PREPARAR O TEMPO
# =========================================================
df_linha <- df_bruto %>%
  # CORREÇÃO: Usar %in% para pegar qualquer ônibus que pertença a uma dessas 3 linhas
  filter(LINE %in% linhas_desejadas) %>%
  # Garante que o timestamp é entendido como tempo matemático pelo R
  mutate(GPSTIMESTAMP = ymd_hms(GPSTIMESTAMP))

print(paste("Total de registros encontrados para as linhas escolhidas:", nrow(df_linha)))

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
  # MELHORIA: Colocamos a "Linha" no nome do trip_id para aparecer bonito no mapa do Python!
  mutate(trip_id = paste0("Linha ", LINE, " (Carro ", BUSID, ")_Parte", sub_viagem_id)) %>%
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

# Exporta usando um nome fixo e claro para esse nosso teste
nome_arquivo <- "rotas_teste_3_linhas.pkl"

pd <- import("pandas")
pd$to_pickle(r_to_py(df_perfeito), nome_arquivo)

print(paste("Sucesso! Arquivo", nome_arquivo, "gerado e pronto para o modelo!"))