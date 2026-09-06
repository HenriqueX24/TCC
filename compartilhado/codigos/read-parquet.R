library(reticulate)

args <- commandArgs(trailingOnly = TRUE)
target_date <- if (length(args) >= 1) args[[1]] else "2023-02-21"
base_url <- "https://mapmob.eic.cefet-rj.br/data"
script_path <- tryCatch(
  normalizePath(sys.frame(1)$ofile),
  error = function(e) NA_character_
)
script_dir <- if (!is.na(script_path)) dirname(script_path) else "compartilhado/codigos"
output_dir <- "local"

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

source_python(file.path(script_dir, "read-parquet.py"))
data <- build_daily_dataset(base_url, target_date)
output_file <- file.path(output_dir, sprintf("G1-%s.RData", target_date))
save(data, file = output_file)

message(sprintf("Arquivo salvo em %s", output_file))
