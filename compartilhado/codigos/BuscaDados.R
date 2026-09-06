library(reticulate)
library(dplyr) # Adicionamos o dplyr para usar o bind_rows()

source_python('read-parquet.py')

dias_da_semana <- as.character(seq(as.Date("2023-02-21"), by = "day", length.out = 7))
letras <- c("A", "B", "C", "D", "E")

# 1. Cria a variável mestre que vai guardar a semana inteira
dados_da_semana_inteira <- NULL 

# 2. Loop dos dias
for (dia in dias_da_semana) {
  
  data_dia <- NULL # Zera a tabela para processar o dia atual
  
  # 3. Loop das letras
  for (letra in letras) {
    link <- paste0("https://mapmob.eic.cefet-rj.br/data/DST-", letra, "/G1-", dia, ".parquet")
    data_tmp <- try(read_parquet(link), silent = TRUE)
    
    # Junta as letras com o merge (sua lógica original)
    if (!inherits(data_tmp, "try-error")) {
      if (is.null(data_dia)) {
        data_dia <- data_tmp 
      } else {
        data_dia <- merge(data_dia, data_tmp) 
      }
    } else {
      message("Parte não encontrada: ", link)
    }
  }
  
  # 4. Terminou de montar o dia? Joga ele dentro da variável da semana!
  if (!is.null(data_dia)) {
    if (is.null(dados_da_semana_inteira)) {
      dados_da_semana_inteira <- data_dia # Se for o primeiro dia, inicia a tabela mestre
    } else {
      # Empilha as linhas do novo dia embaixo dos dias anteriores
      dados_da_semana_inteira <- bind_rows(dados_da_semana_inteira, data_dia) 
    }
    message("Dia ", dia, " processado e adicionado ao pacotão.")
  }
}

# 5. Acabou a semana inteira? Salva o arquivo único!
if (!is.null(dados_da_semana_inteira)) {
  # Renomeia para 'data' para manter o seu padrão
  data <- dados_da_semana_inteira 
  
  nome_rdata <- "G1_Semana_Completa.RData"
  save(data, file = nome_rdata)
  message("Sucesso! Arquivo único gerado: ", nome_rdata)
} else {
  message("Nenhum dado foi encontrado para toda a semana.")
}
