import numpy as np
import pandas as pd
import pyreadr
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import folium
import os

# ==========================
# PARÂMETROS INICIAIS
# ==========================
BUFFER = 100  # metros
LIMIAR = 5  # número de pontos para considerar a tendência
# ==========================

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

# ==========================
# FUNÇÕES AUXILIARES
# ==========================
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
    R = 6371000
    phi1 = np.radians(lat1)
    phi2 = np.radians(lat2)
    dphi = np.radians(lat2 - lat1)
    dlambda = np.radians(lon2 - lon1)
    a = np.sin(dphi / 2.0) ** 2 + np.cos(phi1) * np.cos(phi2) * np.sin(dlambda / 2.0) ** 2
    c = 2 * np.arctan2(np.sqrt(a), np.sqrt(1 - a))
    return R * c

def classify_location(df, A, B, buffer):
    """Classifica a localização de pontos como próximos a A, B ou em trânsito.

    Calcula a distância Haversine de cada ponto no DataFrame aos terminais A e B,
    atribuindo 'A', 'B' ou 'Transito' com base no buffer de proximidade.

    Args:
        df (pandas.DataFrame): DataFrame com colunas 'LONGITUDE' e 'LATITUDE'.
        A (np.ndarray): Coordenadas [longitude, latitude] do terminal A.
        B (np.ndarray): Coordenadas [longitude, latitude] do terminal B.
        buffer (float): Distância máxima (em metros) para considerar proximidade.

    Returns:
        pandas.DataFrame: DataFrame com nova coluna 'LOCALIZACAO' ('A', 'B' ou 'Transito').
    """
    df['dist_A'] = haversine_np(df['LONGITUDE'].values, df['LATITUDE'].values, A[0], A[1])
    df['dist_B'] = haversine_np(df['LONGITUDE'].values, df['LATITUDE'].values, B[0], B[1])

    df['LOCALIZACAO'] = np.where(
        df['dist_A'] <= buffer, 'A',
        np.where(df['dist_B'] <= buffer, 'B', 'Transito')
    )
    return df

def compute_vector_directions(df, A, B):
    """Classifica a direção instantânea de movimento com base no produto escalar.

    Calcula o vetor de deslocamento entre pontos consecutivos e o compara com o vetor
    de referência A→B, atribuindo 'Ida A→B', 'Volta B→A' ou 'Parado/Perpendicular'.

    Args:
        df (pandas.DataFrame): DataFrame com colunas 'LONGITUDE' e 'LATITUDE'.
        A (np.ndarray): Coordenadas [longitude, latitude] do terminal A.
        B (np.ndarray): Coordenadas [longitude, latitude] do terminal B.

    Returns:
        pandas.DataFrame: DataFrame com nova coluna 'VECTOR_DIRECTION'.
    """
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
    return df

def assign_segment_ids(df):
    """Atribui IDs de segmento com base na proximidade aos terminais A ou B.

    Identifica transições entre terminais (A ou B) para criar segmentos de trajeto,
    atribuindo IDs incrementais a cada segmento.

    Args:
        df (pandas.DataFrame): DataFrame com coluna 'LOCALIZACAO' ('A', 'B' ou 'Transito').

    Returns:
        pandas.DataFrame: DataFrame com nova coluna 'SEGMENT_ID' (número ou NaN para pontos fora de segmento).
    """
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
    return df

def classify_segments(df, limiar=5):
    """Classifica segmentos de trajeto como 'Ida', 'Volta' ou 'Indefinido' usando soma acumulada.

    Usa a soma acumulada dos valores numéricos das direções vetoriais para determinar
    a tendência predominante de cada segmento.

    Args:
        df (pandas.DataFrame): DataFrame com colunas 'VECTOR_DIRECTION' e 'SEGMENT_ID'.
        limiar (float): Valor mínimo da soma acumulada para classificar como 'Ida' ou 'Volta'.

    Returns:
        pandas.DataFrame: DataFrame com nova coluna 'SEGMENT_CLASSIFICATION'.

    Notes:
        O limiar padrão é definido como 5, baseado em testes empíricos.
    """
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

        if final_tendency >= limiar:
            classification = 'Ida'
        elif final_tendency <= -limiar:
            classification = 'Volta'
        else:
            classification = 'Indefinido'

        for idx in group.index:
            segment_classification[idx] = classification

    df['SEGMENT_CLASSIFICATION'] = segment_classification
    return df

def plot_segments(df, A, B, filepath):
    """Gera um gráfico de segmentação de trajetos com base na classificação.

    Plota os pontos do trajeto com cores diferentes para 'Ida', 'Volta', 'Indefinido'
    e 'Fora de segmento', marcando os terminais A e B.

    Args:
        df (pandas.DataFrame): DataFrame com colunas 'LONGITUDE', 'LATITUDE', 'SEGMENT_ID', 'SEGMENT_CLASSIFICATION'.
        A (np.ndarray): Coordenadas [longitude, latitude] do terminal A.
        B (np.ndarray): Coordenadas [longitude, latitude] do terminal B.
        filepath (str): Caminho do arquivo de dados para nomear o gráfico.

    Returns:
        None: Exibe o gráfico e não retorna valor.
    """
    # Cores distintas para cada classificação
    colors_map = {
        'Ida': "#000294",  # verde escuro em hexadecimal
        'Volta': 'red',
        'Indefinido': 'gray',
        'Fora de segmento': 'blue'
    }

    # Centro do mapa: média dos pontos
    lat_center = df['LATITUDE'].mean()
    lon_center = df['LONGITUDE'].mean()
    m = folium.Map(location=[lat_center, lon_center], zoom_start=13)

    # Fora de segmento
    fora_segmento = df[df['SEGMENT_ID'].isna()]
    if not fora_segmento.empty:
        folium.PolyLine(
            fora_segmento[['LATITUDE', 'LONGITUDE']].values,
            color=colors_map['Fora de segmento'],
            weight=4,
            opacity=0.7,
            tooltip='Fora de segmento'
        ).add_to(m)

    # Para cada segmento
    for seg_id, group in df.groupby('SEGMENT_ID'):
        classificacao = group['SEGMENT_CLASSIFICATION'].iloc[0]
        cor = colors_map.get(classificacao, 'black')
        folium.PolyLine(
            group[['LATITUDE', 'LONGITUDE']].values,
            color=cor,
            weight=4,
            opacity=0.8,
            tooltip=f'Segmento {seg_id} - {classificacao}'
        ).add_to(m)

    # Pontos A e B
    folium.Marker(
        location=[A[1], A[0]],
        popup='Ponto A (Saída)',
        icon=folium.Icon(color='orange', icon='play')
    ).add_to(m)
    folium.Marker(
        location=[B[1], B[0]],
        popup='Ponto B (Chegada)',
        icon=folium.Icon(color='black', icon='flag')
    ).add_to(m)

    # Salvar mapa como HTML
    map_name = f"mapa_segmentacao_{os.path.splitext(os.path.basename(filepath))[0]}.html"
    m.save(f"data/results/{map_name}")
    print(f"Mapa salvo: {map_name}")

# ==========================
# FUNÇÃO PRINCIPAL POR LINHA
# ==========================
def process_file(filepath, A, B, buffer=50, limiar=5):
    """Processa um arquivo de dados GPS e classifica trajetos de ônibus.

    Executa o pipeline completo de classificação: leitura de dados, ordenação por timestamp,
    classificação de localização, direção vetorial, segmentação e visualização.

    Args:
        filepath (str): Caminho do arquivo RData com os dados GPS.
        A (np.ndarray): Coordenadas [longitude, latitude] do terminal A.
        B (np.ndarray): Coordenadas [longitude, latitude] do terminal B.
        buffer (float): Distância máxima (em metros) para proximidade dos terminais. Padrão: 50.
        limiar (float): Valor mínimo da soma acumulada para classificação de segmentos. Padrão: 5.

    Returns:
        None: Salva o resultado em CSV e exibe gráficos.

    Notes:
        Usa as constantes globais BUFFER e LIMIAR se não fornecidas.
        O arquivo de saída é salvo no diretório atual com o prefixo 'resultado_segmentacao_'.
    """
    result = pyreadr.read_r(filepath)
    df: pd.DataFrame = result['filtered_data']
    df = df.sort_values(by='GPSTIMESTAMP').reset_index(drop=True)

    df = classify_location(df, A, B, buffer)
    df = compute_vector_directions(df, A, B)
    df = assign_segment_ids(df)
    df = classify_segments(df, limiar)
    plot_segments(df, A, B, filepath)

    output_name = f"resultado_segmentacao_{os.path.splitext(os.path.basename(filepath))[0]}.csv"
    df.to_csv(f"data/results/{output_name}", index=False)
    print(f"Arquivo salvo: {output_name}")

# ==========================
# PROCESSAR TODAS AS LINHAS
# ==========================
def process_all_lines(filepaths, pontos_por_linha):
    """Processa múltiplos arquivos de dados GPS para diferentes linhas de ônibus.

    Itera sobre um dicionário de caminhos de arquivos e coordenadas de terminais,
    aplicando o pipeline de classificação para cada linha.

    Args:
        filepaths (dict): Dicionário mapeando IDs de linhas para caminhos de arquivos RData.
        pontos_por_linha (dict): Dicionário com coordenadas dos terminais A e B por linha.

    Returns:
        None: Chama process_file para cada linha e gera saídas correspondentes.
    """
    for linha, filepath in filepaths.items():
        print(f"\nProcessando linha {linha}...")
        pontos = pontos_por_linha.get(linha)
        if not pontos:
            print(f"Pontos não definidos para a linha {linha}. Pulando.")
            continue

        A = np.array(pontos['A'])
        B = np.array(pontos['B'])

        process_file(filepath, A, B, buffer=BUFFER, limiar=LIMIAR)

# ==========================
# MAIN
# ==========================
if __name__ == "__main__":
    filepaths = {
        "343": "data/raw/LINHA_343_C30060_COMPLETO.RData",
        "232": "data/raw/LINHA_232_B25542_COMPLETO.RData",
        "329": "data/raw/LINHA_329_B28528_COMPLETO.RData",
        "390": "data/raw/LINHA_390_C47750_COMPLETO.RData",
        "455": "data/raw/LINHA_455_B71108_COMPLETO.RData",
        "600": "data/raw/LINHA_600_C47603_COMPLETO.RData",
    }

    process_all_lines(filepaths, pontos_por_linha)
