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
    def __init__(self, include_pattern:str, exclude_pattern:str=None, exclude_patterns:List[str]=None):
        self.kldSame: List[float] = []
        self.cramerSame: List[float] = []
        self.bhattacharyyaSame: List[float] = []
        self.kldDiff: List[float] = []
        self.cramerDiff: List[float] = []
        self.bhattacharyyaDiff: List[float] = []

        exclude_files = glob.glob(exclude_pattern) if exclude_pattern else []
        if exclude_patterns:
            for pattern in exclude_patterns:
                exclude_files.extend(glob.glob(pattern))

        for filename in glob.glob(include_pattern):
            if filename in exclude_files:
                print(f"Skipping {filename}")
                continue
            with open(filename, 'r') as file:
                lines = file.readlines()
                for line in lines[1:]: # Drop headers
                    parts = line.strip().split(',')
                    isSame = parts[0] == '1'
                    k, c, b = map(float, parts[1:])
                    if isSame:
                        self.kldSame.append(k)
                        self.cramerSame.append(c)
                        self.bhattacharyyaSame.append(b)
                    else:
                        self.kldDiff.append(k)
                        self.cramerDiff.append(c)
                        self.bhattacharyyaDiff.append(b)

                # print(f"Processed {filename}")
                # print(f"Same: {len(self.kldSame)}")
                # print(f"Different: {len(self.kldDiff)}")


    def average_score(self, same:bool) -> dict[str, float]:
        kld = self.kldSame if same else self.kldDiff
        cramer = self.cramerSame if same else self.cramerDiff
        bhattacharyya = self.bhattacharyyaSame if same else self.bhattacharyyaDiff
        return {
            'avg_kld': sum(kld) / len(kld),
            'avg_cramer': sum(cramer) / len(cramer),
            'avg_bhattacharyya': sum(bhattacharyya) / len(bhattacharyya)
        }

    def minimum_score(self, same:bool) -> dict[str, float]:
        kld = self.kldSame if same else self.kldDiff
        cramer = self.cramerSame if same else self.cramerDiff
        bhattacharyya = self.bhattacharyyaSame if same else self.bhattacharyyaDiff
        return {
            'min_kld': min(kld),
            'min_cramer': min(cramer),
            'min_bhattacharyya': min(bhattacharyya)
        }

    def maximum_score(self, same:bool) -> dict[str, float]:
        kld = self.kldSame if same else self.kldDiff
        cramer = self.cramerSame if same else self.cramerDiff
        bhattacharyya = self.bhattacharyyaSame if same else self.bhattacharyyaDiff
        return {
            'max_kld': max(kld),
            'max_cramer': max(cramer),
            'max_bhattacharyya': max(bhattacharyya)
        }

    def _standard_deviation(self, data: List[float]) -> float:
        mean = sum(data) / len(data)
        variance = sum((x - mean) ** 2 for x in data) / len(data)
        return math.sqrt(variance)

    def standard_deviation(self, same:bool) -> dict[str, float]:
        kld = self.kldSame if same else self.kldDiff
        cramer = self.cramerSame if same else self.cramerDiff
        bhattacharyya = self.bhattacharyyaSame if same else self.bhattacharyyaDiff
        return {
            'stdev_kld': self._standard_deviation(kld),
            'stdev_cramer': self._standard_deviation(cramer),
            'stdev_bhattacharyya': self._standard_deviation(bhattacharyya)
        }

    def standard_error(self, same:bool) -> dict[str, float]:
        kld = self.kldSame if same else self.kldDiff
        cramer = self.cramerSame if same else self.cramerDiff
        bhattacharyya = self.bhattacharyyaSame if same else self.bhattacharyyaDiff
        stdev_kld = self._standard_deviation(kld)
        stdev_cramer = self._standard_deviation(cramer)
        stdev_bhattacharyya = self._standard_deviation(bhattacharyya)
        return {
            'se_kld': stdev_kld / math.sqrt(len(kld)),
            'se_cramer': stdev_cramer / math.sqrt(len(cramer)),
            'se_bhattacharyya': stdev_bhattacharyya / math.sqrt(len(bhattacharyya))
        }

    def scene_metrics(self, include_same=True, include_different=True) -> dict:
        metrics = {}
        if include_same:
            metrics['same'] = {
                'average': self.average_score(True),
                'minimum': self.minimum_score(True),
                'maximum': self.maximum_score(True),
                'standard_deviation': self.standard_deviation(True),
                'standard_error': self.standard_error(True)
            }
        if include_different:
            metrics['different'] = {
                'average': self.average_score(False),
                'minimum': self.minimum_score(False),
                'maximum': self.maximum_score(False),
                'standard_deviation': self.standard_deviation(False),
                'standard_error': self.standard_error(False)
            }
        return metrics

    def summary_table(self, include_same=True, include_different=True) -> Markdown:
        rows = ["Metric [Scene] | Average | Minimum | Maximum | St. Dev. | St. Error"]
        rows.append("---|---|---|---|---|---")
        metrics = self.scene_metrics(include_same, include_different)
        if include_same:
            same = metrics['same']
            same_avg_kld, same_avg_cramer, same_avg_bhattacharyya = same['average'].values()
            same_min_kld, same_min_cramer, same_min_bhattacharyya = same['minimum'].values()
            same_max_kld, same_max_cramer, same_max_bhattacharyya = same['maximum'].values()
            same_stdev_kld, same_stdev_cramer, same_stdev_bhattacharyya = same['standard_deviation'].values()
            same_se_kld, same_se_cramer, same_se_bhattacharyya = same['standard_error'].values()

            rows.append(f"KLD [Same] | {same_avg_kld:.6f} | {same_min_kld:.6f} | {same_max_kld:.6f} | {same_stdev_kld:.6f} | {same_se_kld:.6f}")
            rows.append(f"Cramer [Same] | {same_avg_cramer:.6f} | {same_min_cramer:.6f} | {same_max_cramer:.6f} | {same_stdev_cramer:.6f} | {same_se_cramer:.6f}")
            rows.append(f"Bhattacharyya [Same] | {same_avg_bhattacharyya:.6f} | {same_min_bhattacharyya:.6f} | {same_max_bhattacharyya:.6f} | {same_stdev_bhattacharyya:.6f} | {same_se_bhattacharyya:.6f}")

        if include_different:
            different = metrics['different']
            diff_avg_kld, diff_avg_cramer, diff_avg_bhattacharyya = different['average'].values()
            diff_min_kld, diff_min_cramer, diff_min_bhattacharyya = different['minimum'].values()
            diff_max_kld, diff_max_cramer, diff_max_bhattacharyya = different['maximum'].values()
            diff_stdev_kld, diff_stdev_cramer, diff_stdev_bhattacharyya = different['standard_deviation'].values()
            diff_se_kld, diff_se_cramer, diff_se_bhattacharyya = different['standard_error'].values()

            rows.append(f"KLD [Different] | {diff_avg_kld:.6f} | {diff_min_kld:.6f} | {diff_max_kld:.6f} | {diff_stdev_kld:.6f} | {diff_se_kld:.6f}")
            rows.append(f"Cramer [Different] | {diff_avg_cramer:.6f} | {diff_min_cramer:.6f} | {diff_max_cramer:.6f} | {diff_stdev_cramer:.6f} | {diff_se_cramer:.6f}")
            rows.append(f"Bhattacharyya [Different] | {diff_avg_bhattacharyya:.6f} | {diff_min_bhattacharyya:.6f} | {diff_max_bhattacharyya:.6f} | {diff_stdev_bhattacharyya:.6f} | {diff_se_bhattacharyya:.6f}")

        return Markdown('\n'.join(rows))
