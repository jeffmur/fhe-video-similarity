import math, os, glob
from typing import List
from IPython.display import Markdown

class CompareScores:
    def __init__(self, filename: str):
        self.kldDart: List[float] = []
        self.kldSSO: List[float] = []
        self.cramerDart: List[float] = []
        self.cramerSSO: List[float] = []

        with open(filename, 'r') as file:
            lines = file.readlines()
            for line in lines[1:]:
                parts = line.strip().split(',')
                self.kldDart.append(float(parts[0]))
                self.cramerDart.append(float(parts[1]))
                self.kldSSO.append(float(parts[2]))
                self.cramerSSO.append(float(parts[3]))

    @property
    def scores(self):
        return {
            'kldDart': self.kldDart,
            'kldSSO': self.kldSSO,
            'cramerDart': self.cramerDart,
            'cramerSSO': self.cramerSSO
        }
    
    def standard_deviation(self, data: List[float]) -> float:
        mean = sum(data) / len(data)
        variance = sum((x - mean) ** 2 for x in data) / len(data)
        return math.sqrt(variance)

    def jaccard_coefficent(self, dart: List[float], sso: List[float]) -> float:
        s_dart = set(dart)
        s_sso = set(sso)
        intersection = len(s_dart.intersection(s_sso))
        union = len(s_dart.union(s_sso))
        return intersection / union if union != 0 else 0.0

    def cosine_similarity(self, v1: List[float], v2: List[float]) -> float:
        dot_product = sum(a * b for a, b in zip(v1, v2))
        magnitude_a = math.sqrt(sum(a ** 2 for a in v1))
        magnitude_b = math.sqrt(sum(b ** 2 for b in v2))

        if magnitude_a == 0 or magnitude_b == 0:
            return 0.0  # Cannot compute similarity with zero magnitude

        return dot_product / (magnitude_a * magnitude_b)

class CompareAllScores:
    def __init__(self, directory: str):
        self._directory = directory
        self.scores: dict[str, CompareScores] = {}
        for file in os.listdir(directory):
            if file.endswith('.csv'):
                self.scores[file] = CompareScores(os.path.join(directory, file))

    def avg_standard_deviation(self) -> dict[str, float]:
        scores = self.scores.values()
        return {
            'kldDart_stdev': sum(score.standard_deviation(score.kldDart) for score in scores) / len(scores),
            'kldSSO_stdev': sum(score.standard_deviation(score.kldSSO) for score in scores) / len(scores),
            'cramerDart_stdev': sum(score.standard_deviation(score.cramerDart) for score in scores) / len(scores),
            'cramerSSO_stdev': sum(score.standard_deviation(score.cramerSSO) for score in scores) / len(scores)
        }

    def avg_jaccard_coefficent(self) -> dict[str, float]:
        scores = self.scores.values()
        return {
            'kld_jaccard': sum(score.jaccard_coefficent(score.kldDart, score.kldSSO) for score in scores) / len(scores),
            'cramer_jaccard': sum(score.jaccard_coefficent(score.cramerDart, score.cramerSSO) for score in scores) / len(scores)
        }
    
    def avg_cosine_similarity(self) -> dict[str, float]:
        scores = self.scores.values()
        return {
            'kld_cosine': sum(score.cosine_similarity(score.kldDart, score.kldSSO) for score in scores) / len(scores),
            'cramer_cosine': sum(score.cosine_similarity(score.cramerDart, score.cramerSSO) for score in scores) / len(scores)
        }

class TrainSimilarityScores:
    def __init__(self, include_pattern:str, exclude_pattern:str=None):
        self.isSame: List[bool] = []
        self.kld: List[float] = []
        self.cramer: List[float] = []
        self.bhattacharyya: List[float] = []

        exclude_files = glob.glob(exclude_pattern) if exclude_pattern else []

        for filename in glob.glob(include_pattern):
            if filename in exclude_files:
                print(f"Skipping {filename}")
                continue
            with open(filename, 'r') as file:
                lines = file.readlines()
                for line in lines[1:]: # Drop headers
                    parts = line.strip().split(',')
                    self.isSame.append(parts[0] == '1')
                    self.kld.append(float(parts[1]))
                    self.cramer.append(float(parts[2]))
                    self.bhattacharyya.append(float(parts[3]))

    def average_score(self) -> dict[str, float]:
        return {
            'avg_kld': sum(self.kld) / len(self.kld),
            'avg_cramer': sum(self.cramer) / len(self.cramer),
            'avg_bhattacharyya': sum(self.bhattacharyya) / len(self.bhattacharyya)
        }
    
    def minimum_score(self) -> dict[str, float]:
        return {
            'min_kld': min(self.kld),
            'min_cramer': min(self.cramer),
            'min_bhattacharyya': min(self.bhattacharyya)
        }
    
    def maximum_score(self) -> dict[str, float]:
        return {
            'max_kld': max(self.kld),
            'max_cramer': max(self.cramer),
            'max_bhattacharyya': max(self.bhattacharyya)
        }
    
    def _standard_deviation(self, data: List[float]) -> float:
        mean = sum(data) / len(data)
        variance = sum((x - mean) ** 2 for x in data) / len(data)
        return math.sqrt(variance)

    def standard_deviation(self) -> dict[str, float]:
        return {
            'stdev_kld': self._standard_deviation(self.kld),
            'stdev_cramer': self._standard_deviation(self.cramer),
            'stdev_bhattacharyya': self._standard_deviation(self.bhattacharyya)
        }
    
    def standard_error(self) -> dict[str, float]:
        return {
            'se_kld': self.standard_deviation()['stdev_kld'] / math.sqrt(len(self.kld)),
            'se_cramer': self.standard_deviation()['stdev_cramer'] / math.sqrt(len(self.cramer)),
            'se_bhattacharyya': self.standard_deviation()['stdev_bhattacharyya'] / math.sqrt(len(self.bhattacharyya))
        }
    
    def summary_table(self) -> Markdown:
        rows = ["Metric | Average | Minimum | Maximum | St. Dev. | St. Error"]
        rows.append("---|---|---|---|---|---")
        min_kld, min_cramer, min_bhattacharyya = self.minimum_score().values()
        max_kld, max_cramer, max_bhattacharyya = self.maximum_score().values()
        avg_kld, avg_cramer, avg_bhattacharyya = self.average_score().values()
        stdev_kld, stdev_cramer, stdev_bhattacharyya = self.standard_deviation().values()
        se_kld, se_cramer, se_bhattacharyya = self.standard_error().values()
        rows.append(f'KLD | {avg_kld:.9f} | {min_kld:.9f} | {max_kld:.9f} | {stdev_kld:.9f} | {se_kld:.9f}')
        rows.append(f'Cramer | {avg_cramer:.9f} | {min_cramer:.9f} | {max_cramer:.9f} | {stdev_cramer:.9f} | {se_cramer:.9f}')
        rows.append(f'Bhattacharyya | {avg_bhattacharyya:.9f} | {min_bhattacharyya:.9f} | {max_bhattacharyya:.9f} | {stdev_bhattacharyya:.9f} | {se_bhattacharyya:.9f}')
        return Markdown('\n'.join(rows))
