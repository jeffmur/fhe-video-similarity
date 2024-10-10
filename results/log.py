import csv, re
from datetime import timedelta

def dict_from_str(text: str) -> dict[str, str]:
  match = re.search(r"{([^}]+)}", text)
  if not match: return {}
  return dict(param.split(": ") for param in match.group(1).split(", "))

def timedelta_from_unit(text: str) -> timedelta:
  """
  Parses a string to extract a number and a time unit, and returns a timedelta object.

  Args:
    text (str): The string to parse.

  Returns:
    timedelta: A timedelta object representing the duration.
  """
  match = re.search(r"(\d+)([µ|m]?s)", text)
  if not match: return timedelta()

  number = float(match.group(1))
  unit = match.group(2)
  match unit:
    case 'µs':
      return timedelta(microseconds=number)
    case 'ms':
      return timedelta(milliseconds=number)
    case 's':
      return timedelta(seconds=number)
    case _:
      raise ValueError(f"Unknown unit: {unit}")
    
def parse_number(text:str) -> float:
  """
  Parses a string to find and convert numbers in double or scientific notation.

  Args:
    text (str): The string to parse.

  Returns:
    list: A list of floats representing the extracted numbers.
  """
  # \d+ => one or more digits
  # \.? => optional decimal point
  # \d* => zero or more digits
  # ([eE][+-]?\d+)? => optional scientific notation part
  pattern = r"[+-]?\d*\.?\d+(?:[eE][+-]?\d+)?"
  number_matches = re.findall(pattern, text)
  if not number_matches: return []

  return float(number_matches[0])

class LogEntry:
  """
  Represents a single log entry. CorrelationId is optional.
  """
  def __init__(self, timestamp:str, log_level:str, message:str, correlation_id=None):
      self.timestamp = timestamp
      self.log_level = log_level
      self.message = message
      self.correlation_id = correlation_id
      emojis = re.findall(r'[⚙📊]', message)
      self.emoji = emojis[0] if emojis else None

class ProcessedMetric(LogEntry):
  """
  Model for a processed log entry.
  """
  def __init__(self, timestamp, log_level, message, correlation_id):
    super().__init__(timestamp, log_level, message, correlation_id)
    self.duration = timedelta_from_unit(message.split('{')[0])
    self.params = dict_from_str(message)

class SimilarityScoreMetric(LogEntry):
  """
  Model for a similarity score log entry.
  """
  def __init__(self, timestamp, log_level, message):
    super().__init__(timestamp, log_level, message)
    score_match = re.search(r"=>\s+([\d.eE+-]+)\s", message)
    if score_match:
      self.score = parse_number(score_match.group(1))

    self.name = str(message.split(' ')[1]) # Algorithm


class BaselineSimilarityScoreMetric(SimilarityScoreMetric):
  """
  Model for a similarity score log entry.
  """
  def __init__(self, timestamp, log_level, message):
    super().__init__(timestamp, log_level, message)
    self.try_set_duration()

  def try_set_duration(self):
    duration_match = re.search(r"took (\d+[µ|m]?s)", self.message)

    if duration_match:
      self.duration = timedelta_from_unit(duration_match.group(1))

class CiphertextSimilarityScoreMetric(SimilarityScoreMetric):
  """
  Model for a similarity score log entry.
  """
  def __init__(self, timestamp, log_level, message):
    super().__init__(timestamp, log_level, message)
    self.try_set_durations()

  def try_set_durations(self):
    duration_match = re.search(r"total: (\d+[µ|m]?s)", self.message)

    if duration_match:
      self.duration = timedelta_from_unit(duration_match.group(1))

    duration_dict = dict_from_str('{' + self.message.split(' in ')[1] + '}')
    self.ciphertext_duration = {key : timedelta_from_unit(value) for key, value in duration_dict.items()}

class LogParser:
    """
    Extract Logs from a CSV file.
    """
    def __init__(self, filename):
        self.filename = filename
        self.entries = list(self._parse())

    def _parse(self):
        with open(self.filename, 'r') as f:
            reader = csv.reader(f, delimiter=';')
            next(reader)  # Skip header
            for row in reader:
                yield LogEntry(*row)

    def all(self):
        for i in self.entries:
          match(i.log_level):
            case 'METRIC':
              if "Processed" in i.message:
                yield ProcessedMetric(i.timestamp, i.log_level, i.message, i.correlation_id)
              elif "Plaintext Score" in i.message:
                yield BaselineSimilarityScoreMetric(i.timestamp, i.log_level, i.message)
              elif "Ciphertext Score" in i.message:
                yield CiphertextSimilarityScoreMetric(i.timestamp, i.log_level, i.message)

    def filter_by_metric(self, classType: LogEntry):
        """
        Used to aggregate logs of the same type.
        """
        for i in list(self.all()):
            if isinstance(i, classType):
                yield i

    def filter_by_similarity_algorithm(self, algorithm: str, classType=SimilarityScoreMetric):
        """
        Used to aggregate metrics of the same algorithm.
        """
        for i in list(self.all()):
            if isinstance(i, classType) and i.name.lower() == algorithm.lower():
                yield i

# Every log file contains a set of Similarity Score Metrics (score + encryption time + baseline time)
# log files may contain pre-processing metrics (duration)

class ImportSimilarityScores():
    def __init__(self, filename:str, debug=False):
        self._debug = debug
        self.parser = LogParser(filename)
        self.all_logs = list(self.parser.all())
        self.baseline_similarity_scores = list(self.parser.filter_by_metric(BaselineSimilarityScoreMetric))
        self.ciphertext_similarity_scores = list(self.parser.filter_by_metric(CiphertextSimilarityScoreMetric))

        self.kld_similarity_scores = list(self.parser.filter_by_similarity_algorithm("kld"))
        self.kld_baseline_similarity_scores = list(self.parser.filter_by_similarity_algorithm("kld", BaselineSimilarityScoreMetric))
        self.kld_ciphertext_similarity_scores = list(self.parser.filter_by_similarity_algorithm("kld", CiphertextSimilarityScoreMetric))

        self.bhattacharyya_similarity_scores = list(self.parser.filter_by_similarity_algorithm("bhattacharyya"))
        self.bhattacharyya_baseline_similarity_scores = list(self.parser.filter_by_similarity_algorithm("bhattacharyya", BaselineSimilarityScoreMetric))
        self.bhattacharyya_ciphertext_similarity_scores = list(self.parser.filter_by_similarity_algorithm("bhattacharyya", CiphertextSimilarityScoreMetric))

        self.cramer_similarity_scores = list(self.parser.filter_by_similarity_algorithm("cramer"))
        self.cramer_baseline_similarity_scores = list(self.parser.filter_by_similarity_algorithm("cramer", BaselineSimilarityScoreMetric))
        self.cramer_ciphertext_similarity_scores = list(self.parser.filter_by_similarity_algorithm("cramer", CiphertextSimilarityScoreMetric))
    
    def info(self):
        print('--- ImportSimilarityScores ---')
        print(f"({len(self.all_logs)}) Logs in total")
        print(f"({len(self.baseline_similarity_scores)}) BaselineSimilarityScoreMetric")
        print(f" - ({len(self.kld_baseline_similarity_scores)}) KLD")
        print(f" - ({len(self.bhattacharyya_baseline_similarity_scores)}) Bhattacharyya")
        print(f" - ({len(self.cramer_baseline_similarity_scores)}) Cramer")
        print(f"({len(self.ciphertext_similarity_scores)}) CiphertextSimilarityScoreMetric")
        print(f" - ({len(self.kld_ciphertext_similarity_scores)}) KLD")
        print(f" - ({len(self.bhattacharyya_ciphertext_similarity_scores)}) Bhattacharyya")
        print(f" - ({len(self.cramer_ciphertext_similarity_scores)}) Cramer")
        print('------------------------------')

    def score_diff(self, algorithm: str) -> float:
        """
        Compare the similarity scores of the baseline and ciphertext for a given algorithm.
        """
        baseline = list(self.parser.filter_by_similarity_algorithm(algorithm, BaselineSimilarityScoreMetric))
        ciphertext = list(self.parser.filter_by_similarity_algorithm(algorithm, CiphertextSimilarityScoreMetric))

        if not baseline or not ciphertext:
           assert False, f"Missing logs for {algorithm}"

        if self._debug:
          print(f"Comparing {algorithm} similarity scores")
          print(f"Baseline scores: {[i.score for i in baseline]}")
          print(f"Ciphertext scores: {[i.score for i in ciphertext]}")

        return abs(sum([i.score for i in baseline]) - sum([i.score for i in ciphertext]))

    def duration_diff_µs(self, algorithm: str) -> float:
        """
        Compare the encryption times of the baseline and ciphertext for a given algorithm.
        """
        baseline = list(self.parser.filter_by_similarity_algorithm(algorithm, BaselineSimilarityScoreMetric))
        ciphertext = list(self.parser.filter_by_similarity_algorithm(algorithm, CiphertextSimilarityScoreMetric))

        if not baseline or not ciphertext:
           assert False, f"Missing logs for {algorithm}"

        if self._debug:
          print(f"Comparing {algorithm} durations")
          print(f"Baseline durations: {[i.duration for i in baseline]}")
          print(f"Ciphertext durations: {[i.duration for i in ciphertext]}")

        return abs(sum([i.duration.microseconds for i in baseline]) - sum([i.duration.microseconds for i in ciphertext]))

