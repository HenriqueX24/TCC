# 1. Sorteia uma linha inicial (garantindo que não vai sortear muito pro final e faltar espaço)
linha_inicial <- sample(1:(nrow(onibus_escolhido) - 99), 1)

# 2. Cria o novo banco fatiando da linha inicial até as próximas 99 linhas (total de 100)
novo_dado <- onibus_escolhido[linha_inicial:(linha_inicial + 99), ]

# Visualiza o resultado para confirmar
View(novo_dado)
