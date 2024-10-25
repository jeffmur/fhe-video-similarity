import math, os
from typing import List, Set

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

