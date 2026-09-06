import pandas as pd


def read_parquet(filename):
  df = pd.read_parquet(filename)
  print(f"Parquet carregado: {filename} ({len(df)} linhas)")
  return df.reset_index(drop=True)


def read_parquet_aggregated(filename, group_by="ID", drop_columns=None, agg="max"):
  df = read_parquet(filename)
  return deduplicate_dataframe(df, subset=[group_by], drop_columns=drop_columns, keep="last")


def deduplicate_dataframe(df, subset=None, drop_columns=None, keep="last"):
  subset = subset or ["ID"]

  if any(column not in df.columns for column in subset):
    return df.reset_index(drop=True)

  drop_columns = set(drop_columns or [])
  keep_columns = [col for col in df.columns if col not in drop_columns]
  df = df.loc[:, keep_columns]

  deduplicated = df.drop_duplicates(subset=subset, keep=keep).reset_index(drop=True)
  print(
    f"Duplicatas removidas por {subset}: {len(df)} -> {len(deduplicated)} linhas"
  )
  return deduplicated


def merge_dataframes(left_df, right_df, join_key="ID", how="left", suffixes=(".x", ".y")):
  merged = left_df.merge(right_df, on=join_key, how=how, suffixes=suffixes)
  return merged.reset_index(drop=True)


def build_daily_dataset(base_url, target_date):
  datasets = {
    "DST-A": None,
    "DST-B": ["SWVERSION"],
    "DST-C": ["SWVERSION"],
    "DST-D": ["SWVERSION"],
    "DST-E": ["SWVERSION"],
  }

  base_df = None

  for folder, drop_columns in datasets.items():
    file_url = f"{base_url}/{folder}/G1-{target_date}.parquet"

    try:
      dataset = read_parquet_aggregated(
        file_url,
        group_by="ID",
        drop_columns=drop_columns,
      )
    except Exception:
      if folder == "DST-A":
        raise

      print(f"Arquivo indisponivel: {file_url}")
      continue

    if base_df is None:
      base_df = dataset
      print(f"Base inicial pronta: {folder} ({len(base_df)} linhas)")
      continue

    base_df = merge_dataframes(base_df, dataset, join_key="ID", how="left")
    print(f"Merge concluido: {folder} ({len(base_df)} linhas)")

  if base_df is None:
    raise ValueError(
      f"Nao foi possivel carregar a base principal DST-A para a data {target_date}"
    )

  print(f"Dataset final pronto: {len(base_df)} linhas")
  return base_df.reset_index(drop=True)
