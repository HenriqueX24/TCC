import numpy as np
import pandas as pd
import pyreadr
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import glob
import os

# ==========================
# DICIONÁRIO DE PONTOS POR LINHA
# ==========================
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

# Função haversine em numpy
def haversine_np(lon1, lat1, lon2, lat2):
    """Calcula a distância Haversine entre dois pontos na Terra.

    Usa a fórmula de Haversine para determinar a distância geodésica entre dois pontos
    definidos por longitude e latitude, considerando a curvatura da Terra.

    Args:
        lon1 (float or np.ndarray): Longitude do primeiro ponto em graus.
        lat1 (float or np.ndarray): Latitude do primeiro ponto em graus.
        lon2 (float or np.ndarray): Longitude do segundo ponto em graus.
        lat2 (float or np.ndarray): Latitude do segundo ponto em graus.

    Returns:
        float or np.ndarray: Distância em metros entre os pontos.

    Notes:
        O raio da Terra é fixado em 6.371.000 metros.
    """
    R = 6371000  # raio da Terra em metros
    phi1 = np.radians(lat1)
    phi2 = np.radians(lat2)
    dphi = np.radians(lat2 - lat1)
    dlambda = np.radians(lon2 - lon1)
    a = np.sin(dphi / 2.0) ** 2 + np.cos(phi1) * np.cos(phi2) * np.sin(dlambda / 2.0) ** 2
    c = 2 * np.arctan2(np.sqrt(a), np.sqrt(1 - a))
    return R * c

def process_file(filepath, buffer=50, limiar=0.8):
    """Processa um arquivo de dados GPS para classificar trajetos de ônibus.

    Aplica o pipeline de classificação: leitura de dados, identificação de terminais,
    cálculo de direções vetoriais, segmentação e visualização para a linha 343.

    Args:
        filepath (str): Caminho do arquivo RData com os dados GPS.
        buffer (float): Distância máxima (em metros) para proximidade dos terminais. Padrão: 50.
        limiar (float): Valor mínimo da soma acumulada para classificação de segmentos. Padrão: 0.8.

    Returns:
        None: Salva o resultado em 'resultado_segmentacao.csv' e exibe um gráfico.

    Notes:
        Usa coordenadas fixas para os terminais A e B da linha 343.
        O limiar padrão de 0.8 é ajustado para a linha 343; outros valores são usados em testes.
    """
    result = pyreadr.read_r(filepath)
    # Verifica as possíveis chaves
    if 'filtered_data' in result:
        df: pd.DataFrame = result['filtered_data']
    elif 'data_filtrada' in result:
        df: pd.DataFrame = result['data_filtrada']
    else:
        raise ValueError(f"Chave de DataFrame não encontrada em {filepath}.")
    df = df.sort_values(by='ID').reset_index(drop=True)

    # Extrai o número da linha do nome do arquivo
    file_name = os.path.basename(filepath)
    linha_num = file_name.split('_')[1]

    # Usa o dicionário para definir A e B
    pontos = pontos_por_linha.get(linha_num)
    if not pontos:
        print(f"Pontos não definidos para a linha {linha_num}. Pulando arquivo.")
        return

    A = np.array(pontos["A"])
    B = np.array(pontos["B"])

    df['dist_A'] = haversine_np(df['LONGITUDE'].values, df['LATITUDE'].values, A[0], A[1])
    df['dist_B'] = haversine_np(df['LONGITUDE'].values, df['LATITUDE'].values, B[0], B[1])

    df['LOCALIZACAO'] = np.where(
        df['dist_A'] <= buffer, 'A',
        np.where(df['dist_B'] <= buffer, 'B', 'Transito')
    )

    vector_AB = B - A
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
            direction = "Ida A→B"
        elif dot_product < 0:
            direction = "Volta B→A"
        else:
            direction = "Parado/Perpendicular"
        vector_directions.append(direction)
    df['VECTOR_DIRECTION'] = vector_directions

    segment_ids = []
    current_segment_id = 0
    last_terminal = None

    for idx, row in df.iterrows():
        loc = row['LOCALIZACAO']
        if loc in ['A', 'B']:
            if loc != last_terminal:
                current_segment_id += 1
                last_terminal = loc
        segment_ids.append(current_segment_id if last_terminal else np.nan)

    df['SEGMENT_ID'] = segment_ids

    # Mapear direcao vetorial para valores numericos
    direction_map = {
        'Ida A→B': 1,
        'Volta B→A': -1
    }
    df['DIRECTION_NUM'] = df['VECTOR_DIRECTION'].map(direction_map).fillna(0)

    segment_classification = ['Fora de segmento'] * len(df)

    for seg_id, group in df.groupby('SEGMENT_ID'):
        if pd.isna(seg_id):
            continue

        cumsum = group['DIRECTION_NUM'].cumsum()
        final_tendency = cumsum.iloc[-1]

        if final_tendency >= 5:
            classification = 'Ida'
        elif final_tendency <= -5:
            classification = 'Volta'
        else:
            classification = 'Indefinido'

        for idx in group.index:
            segment_classification[idx] = classification

    df['SEGMENT_CLASSIFICATION'] = segment_classification

    colors_map = {
        'Ida': 'green',
        'Volta': 'red',
        'Indefinido': 'gray',
        'Fora de segmento': 'blue'
    }

    plt.figure(figsize=(12, 6))
    for seg_id, group in df.groupby('SEGMENT_ID'):
        if pd.isna(seg_id):
            continue
        classificacao = group['SEGMENT_CLASSIFICATION'].iloc[0]
        cor = colors_map.get(classificacao, 'black')
        plt.plot(group['LONGITUDE'], group['LATITUDE'], color=cor, linewidth=2)
        plt.scatter(group['LONGITUDE'], group['LATITUDE'], color=cor, s=10)

    plt.scatter(*A, color='orange', label='Ponto A (Saída)', marker='x', s=100, zorder=5)
    plt.scatter(*B, color='black', label='Ponto B (Chegada)', marker='x', s=100, zorder=5)

    plt.title(f"Segmentação com Tendência de Cumsum - {os.path.splitext(os.path.basename(filepath))[0]}")
    plt.xlabel("Longitude")
    plt.ylabel("Latitude")
    plt.grid(True)
    plt.axis('equal')
    plt.legend(handles=[
        mpatches.Patch(color='green', label='Ida'),
        mpatches.Patch(color='red', label='Volta'),
        mpatches.Patch(color='gray', label='Indefinido'),
        mpatches.Patch(color='blue', label='Fora de segmento'),
        plt.Line2D([], [], marker='x', color='orange', label='Ponto A (Saída)', markerfacecolor='orange', markersize=8, linestyle='None'),
        plt.Line2D([], [], marker='x', color='black', label='Ponto B (Chegada)', markerfacecolor='black', markersize=8, linestyle='None')
    ])
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    data_dir = "data/raw/"
    pattern = os.path.join(data_dir, "LINHA_*_IDA_VOLTA.RData")
    files = glob.glob(pattern)
    for file_path in files:
        process_file(file_path)
