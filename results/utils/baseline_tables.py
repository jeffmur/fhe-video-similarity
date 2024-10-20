from utils.csv import CompareAllScores
import textwrap, os
from IPython.display import Markdown

def verbose_kld_cramer(pathToDir:str):
    "Compare the KLD and Cramer scores for Dart and SSO for broken down for each csv file"
    s = CompareAllScores(pathToDir)
    rows = []
    rows.append("File | KLD SSO σ | KLD Dart σ | KLD SSO ± Dart σ | Cramer SSO σ | Cramer Dart σ | Cramer SSO ± Dart σ")
    rows.append("---|---|---|---|---|---|---")
    for file in s.scores.keys():
        ss = s.scores[file]
        kldDart_stdev = ss.standard_deviation(ss.kldDart)
        kldSSO_stdev = ss.standard_deviation(ss.kldSSO)
        abs_diff_kld = abs(kldDart_stdev - kldSSO_stdev)

        cramerDart_stdev = ss.standard_deviation(ss.cramerDart)
        cramerSSO_stdev = ss.standard_deviation(ss.cramerSSO)
        abs_diff_cramer = abs(cramerDart_stdev - cramerSSO_stdev)

        rows.append(f"{file} | {kldSSO_stdev:.6f} | {kldDart_stdev:.6f} | {abs_diff_kld:.6f} | {cramerSSO_stdev:.6f} | {cramerDart_stdev:.6f} | {abs_diff_cramer:.6f}")

    return Markdown(textwrap.dedent('\n'.join(rows)))

def summary_kld_cramer(pathToDir:str):
    "Compare the KLD and Cramer scores for Dart and SSO for all csv files"
    s = CompareAllScores(pathToDir)
    kldDart_stdev, kldSSO_stdev, cramerDart_stdev, cramerSSO_stdev = s.avg_standard_deviation().values()
    rows = []
    rows.append("Algorithm | Avg. Standard Deviation")
    rows.append("---|---")
    rows.append(f"KLD Dart | {kldDart_stdev:.6f}")
    rows.append(f"KLD SSO  | {kldSSO_stdev:.6f}")
    rows.append(f"Cramer Dart | {cramerDart_stdev:.6f}")
    rows.append(f"Cramer SSO | {cramerSSO_stdev:.6f}")

    return Markdown(textwrap.dedent('\n'.join(rows)))
