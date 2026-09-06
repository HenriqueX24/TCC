# Tratamento de linhas para gerar o DF de cada linha de onibus organizado por tempo

library(dplyr)

#Remove todos os onibus que ficam parados o dia todo
linhas_alvo <- c(322, 323, 324, 326, 327, 328, 329)
#linhas_alvo <- c(328)

df_alvo <- subset(data, LINE %in% linhas_alvo)

df_alvo$LINE <- as.factor(df_alvo$LINE)

# Calcula velocidade média por ônibus
media_vel_por_onibus <- aggregate(VELOCITY ~ BUSID, data = df_alvo, mean, na.rm = TRUE)

# Mantém apenas ônibus com média > 0
onibus_ativos <- media_vel_por_onibus$BUSID[media_vel_por_onibus$VELOCITY > 1]

df_ativo <- subset(df_alvo, BUSID %in% onibus_ativos)

data <- df_ativo


#SEPARA POR LINHA DE ÔNIBUS

line321 <- data[data$LINE == 321, ]
#line322 <- data[data$LINE == 322, ] #sem registros
#line323 <- data[data$LINE == 323, ] #sem registros
line324 <- data[data$LINE == 324, ]
line325 <- data[data$LINE == 325, ]
line326 <- data[data$LINE == 326, ]
#line327 <- data[data$LINE == 327, ] #sem registros
line328 <- data[data$LINE == 328, ]
line329 <- data[data$LINE == 329, ]

#ORGANIZA POR TIMESTAMP

line324 <- line324[order(line324$GPSTIMESTAMP), ]
line326 <- line326[order(line326$GPSTIMESTAMP), ]
line328 <- line328[order(line328$GPSTIMESTAMP), ]
line329 <- line329[order(line329$GPSTIMESTAMP), ]

#FAZ O SPLIT DO DATAFRAME POR BUSID

bus_list324 <- split(line324, line324$BUSID)
bus_list326 <- split(line326, line326$BUSID)
bus_list328 <- split(line328, line328$BUSID)
bus_list329 <- split(line329, line329$BUSID)
# Ex: View(bus_list321[["B28540"]])

filtrar_onibus <- function(lista, min_linhas = 80) {
  lista[sapply(lista, nrow) >= min_linhas]
}

bus_list324 <- filtrar_onibus(bus_list324, 80)
bus_list326 <- filtrar_onibus(bus_list326, 80)
bus_list328 <- filtrar_onibus(bus_list328, 80)
bus_list329 <- filtrar_onibus(bus_list329, 80)
