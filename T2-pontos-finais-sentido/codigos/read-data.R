if (!requireNamespace("leaflet", quietly = TRUE)) {
  install.packages("leaflet")
}
library(leaflet)
library(dplyr)
library(ggplot2)
library(lubridate)

load("./data/G1-2023-02-21.RData")

plot_bus_trip <- function(data, selected_line, direction = c("ida", "volta", "ida_volta")) {
  # Tabela com parâmetros por linha
  line_times <- tibble::tribble(
    ~LINE, ~BUSID,     ~start_time,                          ~duration_ida_min, ~duration_ida_sec, ~duration_volta_min,
    "343", "C30060",   as.POSIXct("2023-02-21 12:50:30"),    129,               30,                104,
    "600", "C47603",   as.POSIXct("2023-02-21 13:30:00"),    80,               0,                 93,
    "390", "C47750",   as.POSIXct("2023-02-21 11:45:00"),    136,               0,                 105,
    "329", "B28528",   as.POSIXct("2023-02-21 00:00:00"),    360,               0,                 300,
    "455", "B71108",   as.POSIXct("2023-02-21 12:32:00"),    65,               0,                 110,
    "232", "B25542",   as.POSIXct("2023-02-21 13:19:13"),    49,               0,                 45,
  )
  
  # Busca parâmetros da linha escolhida
  params <- line_times |> filter(LINE == selected_line)
  
  if (nrow(params) == 0) {
    message("Linha não encontrada na tabela de parâmetros.")
    return(NULL)
  }
  
  # Cálculo de tempos
  start_time_ida <- params$start_time
  end_time_ida <- start_time_ida + minutes(params$duration_ida_min) + seconds(params$duration_ida_sec)
  
  start_time_volta <- end_time_ida
  end_time_volta <- start_time_volta + minutes(params$duration_volta_min)
  
  if (direction == "ida") {
    start_time_total <- start_time_ida
    end_time_total <- end_time_ida
  } else if (direction == "volta") {
    start_time_total <- start_time_volta
    end_time_total <- end_time_volta
  } else if (direction == "ida_volta") {
    start_time_total <- start_time_ida
    end_time_total <- end_time_volta
  }
  
  # Filtragem dos dados
  filtered_data <- data |>
    filter(
      LINE == params$LINE,
      BUSID == params$BUSID,
      GPSTIMESTAMP >= start_time_total,
      GPSTIMESTAMP <= end_time_total
    )
  
  if (nrow(filtered_data) == 0) {
    message(paste0("Nenhum dado encontrado para a linha ", selected_line, " dentro do intervalo de tempo."))
    return(NULL)
  }
  
  
  # Popup para o mapa
  filtered_data <- filtered_data |>
    mutate(
      popup_text = paste0(
        "<b>Timestamp:</b> ", GPSTIMESTAMP, "<br>",
        "<b>Velocity:</b> ", VELOCITY, " km/h<br>",
        "<b>Neighborhood:</b> ", NEIGHBORHOOD, "<br>",
        "<b>Latitude:</b> ", LATITUDE, "<br>",
        "<b>Longitude:</b> ", LONGITUDE
      )
    )
  
  # Paleta por bairro
  neighborhoods <- unique(filtered_data$NEIGHBORHOOD)
  pal <- colorFactor(palette = rainbow(length(neighborhoods)), domain = neighborhoods)
  
  # Mapa leaflet
  leaflet(filtered_data) |>
    addTiles() |>
    addPolylines(~LONGITUDE, ~LATITUDE, color = "blue", weight = 3, opacity = 1) |>
    addCircleMarkers(
      ~LONGITUDE, ~LATITUDE,
      radius = 5,
      fillColor = "red",
      fillOpacity = 0.9,
      stroke = TRUE,
      color = "white",
      weight = 1,
      popup = ~popup_text
    )
  
  #file_name <- paste0("LINHA_", selected_line, "_", toupper(direction), ".RData")
  #save(filtered_data, file =  paste0("data/",file_name))
}

plot_bus_trip(data, "343", "ida")

line_numbers <- c("343", "600", "390", "329", "455", "232")
directions <- c("ida", "volta", "ida_volta")
for (line in line_numbers) {
  for (dir in directions) {
    plot_bus_trip(data, line, dir)
  }
}
