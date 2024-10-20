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

    def jaccard(self, dart: Set, sso: Set) -> float:
        intersection = len(dart.intersection(sso))
        union = len(dart.union(sso))
        return intersection / union if union != 0 else 0.0

    def cosine(self, v1: List[float], v2: List[float]) -> float:
        dot_product = sum(a * b for a, b in zip(v1, v2))
        magnitude_a = math.sqrt(sum(a ** 2 for a in v1))
        magnitude_b = math.sqrt(sum(b ** 2 for b in v2))

        if magnitude_a == 0 or magnitude_b == 0:
            return 0.0  # Cannot compute similarity with zero magnitude

        return dot_product / (magnitude_a * magnitude_b)

class CompareAllScores:
    def __init__(self, directory: str):
        self._directory = directory
        self._scores: Set[CompareScores] = set()
        self._files = []
        for file in os.listdir(directory):
            if file.endswith('.csv'):
                self._files.append(file)
                self._scores.add(CompareScores(os.path.join(directory, file)))

    @property
    def scores(self) -> dict[str, CompareScores]:
        return {file: score for file, score in sorted(zip(self._files, self._scores), key=lambda x: x[0])}

    def avg_standard_deviation(self) -> dict[str, float]:
        return {
            'kldDart_stdev': sum(score.standard_deviation(score.kldDart) for score in self._scores) / len(self._scores),
            'kldSSO_stdev': sum(score.standard_deviation(score.kldSSO) for score in self._scores) / len(self._scores),
            'cramerDart_stdev': sum(score.standard_deviation(score.cramerDart) for score in self._scores) / len(self._scores),
            'cramerSSO_stdev': sum(score.standard_deviation(score.cramerSSO) for score in self._scores) / len(self._scores)
        }

