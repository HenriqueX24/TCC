import numpy as np
import pandas as pd
import pyreadr
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import glob
import os

# === 1. Loop pelos arquivos LINHA_{NUMBER}_COMPLETO.RData ===
data_dir = "data/raw/"
pattern = os.path.join(data_dir, "LINHA_[0-9][0-9][0-9]_VOLTA.RData")
files = glob.glob(pattern)

pontos_por_linha = {
    "343": {
        "A": [-43.31261, -23.00516],
        "B": [-43.19369, -22.90568]
    },
    "232": {
        "A": [-43.29042, -22.90076],
        "B": [-43.18941, -22.90825]
    },
    "390": {
        "A": [-43.39373, -22.95652],
        "B": [-43.19241, -22.90532]
    },
    "455": {
        "A": [-43.28039, -22.89977],
        "B": [-43.19089, -22.98671]
    },
    "600": {
        "A": [-43.40513, -22.91282],
        "B": [-43.22491, -22.92070]
    }
}

for file_path in files:
    result = pyreadr.read_r(file_path)
    # Tenta obter o DataFrame usando as possíveis chaves
    if 'filtered_data' in result:
        df: pd.DataFrame = result['filtered_data']
    elif 'data_filtrada' in result:
        df: pd.DataFrame = result['data_filtrada']
    else:
        raise ValueError(f"Chave de DataFrame não encontrada em {file_path}.")

    # Extrai o número da linha do nome do arquivo
    file_name = os.path.basename(file_path)
    linha_num = file_name.split('_')[1]

    # Usa o dicionário para definir A e B
    pontos = pontos_por_linha.get(linha_num)
    if not pontos:
        print(f"Pontos não definidos para a linha {linha_num}. Pulando arquivo.")
        continue

    A = np.array(pontos["A"])
    B = np.array(pontos["B"])
    vector_AB = B - A

    # === 3. Cálculo da direção usando produto escalar ===
    vector_directions = []

    for i in range(len(df)):
        if i == 0 or i == len(df) - 1:
            vector_directions.append("NA")
            continue

        next_point = np.array([df.iloc[i + 1]['LONGITUDE'], df.iloc[i + 1]['LATITUDE']])
        current_point = np.array([df.iloc[i]['LONGITUDE'], df.iloc[i]['LATITUDE']])
        movement_vector = next_point - current_point

        dot_product = np.dot(movement_vector, vector_AB)

        if dot_product > 0:
            direction = "Ida A → B"
        elif dot_product < 0:
            direction = "Volta B → A"
        else:
            direction = "Parado/Perpendicular"

        vector_directions.append(direction)

    df['VECTOR_DIRECTION'] = vector_directions

    # === 4. Plot do trajeto com cores por direção ===
    colors = ['green' if d == "Ida A → B" else 'red' if d == "Volta B → A" else 'blue' for d in df['VECTOR_DIRECTION']]

    plt.figure(figsize=(12, 6))
    plt.scatter(df['LONGITUDE'], df['LATITUDE'], c=colors, s=10)
    plt.plot(df['LONGITUDE'], df['LATITUDE'], linestyle='--', alpha=0.5)

    plt.scatter(*A, color='black', label='Ponto A (Chegada)', zorder=5)
    plt.scatter(*B, color='orange', label='Ponto B (Saída)', zorder=5)

    green_patch = mpatches.Patch(color='green', label='Ida A → B')
    red_patch = mpatches.Patch(color='red', label='Volta B → A')
    blue_patch = mpatches.Patch(color='blue', label='Parado/Indefinido')

    plt.title(f"Direção do Trajeto ({os.path.basename(file_path)})")
    plt.xlabel("Longitude")
    plt.ylabel("Latitude")
    plt.grid(True)
    plt.axis('equal')
    plt.legend(handles=[
        green_patch, red_patch, blue_patch,
        plt.Line2D([], [], marker='o', color='w', label='Ponto A (Chegada)', markerfacecolor='black', markersize=8),
        plt.Line2D([], [], marker='o', color='w', label='Ponto B (Saída)', markerfacecolor='orange', markersize=8)
    ])
    plt.show()
