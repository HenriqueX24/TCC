library(reticulate)
library(dplyr)

source_python('read-parquet.py')

# 1. Configuracoes de datas, letras e alvos
dias_da_semana <- as.character(seq(as.Date("2023-03-01"), by = "day", length.out = 7))
letras <- c("A", "B", "C", "D", "E")
alvos_desejados <- c("321", "322", "323", "324", "325", "326", "327", "328", "329")

dados_da_semana_inteira <- NULL 

# 2. Loop dos dias
for (dia in dias_da_semana) {
  
  data_dia <- NULL 
  
  # 3. Loop das letras para montar o dia atual
  for (letra in letras) {
    link <- paste0("https://mapmob.eic.cefet-rj.br/data/DST-", letra, "/G1-", dia, ".parquet")
    data_tmp <- try(read_parquet(link), silent = TRUE)
    
    # Junta as letras com merge
    if (!inherits(data_tmp, "try-error")) {
      if (is.null(data_dia)) {
        data_dia <- data_tmp 
      } else {
        data_dia <- merge(data_dia, data_tmp) 
      }
    } else {
      message("Parte nao encontrada: ", link)
    }
  }
  
  # 4. Filtra o dia montado e empilha no banco da semana
  if (!is.null(data_dia)) {
    
    # Aplica o filtro selecionando apenas as linhas desejadas
    data_dia <- data_dia %>%
      filter(LINE %in% alvos_desejados)
    
    # Empilha no banco principal
    if (is.null(dados_da_semana_inteira)) {
      dados_da_semana_inteira <- data_dia 
    } else {
      dados_da_semana_inteira <- bind_rows(dados_da_semana_inteira, data_dia) 
    }
    
    message("Dia processado, filtrado e empilhado: ", dia)
  }
}

# 5. Salva o resultado final filtrado
if (!is.null(dados_da_semana_inteira)) {
  
  # Renomeia para manter o seu padrao
  data <- dados_da_semana_inteira 
  
  save(data, file = "G1_Filtrado_Final.RData")
  message("Processo concluido. Arquivo unico salvo.")
  
} else {
  message("Nenhum dado encontrado para toda a semana.")
}
