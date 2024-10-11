import textwrap
from IPython.display import Markdown
from utils.accuracy import *
from utils.performance import *

def compute_diff(fhe:float, plain:float) -> float:
    return abs(fhe - plain)

def compute_diff_dict(fhe:dict, plain:dict) -> dict:
    return {k: compute_diff(fhe[k], plain[k]) for k in fhe}

def compute_growth_percentage(fhe:float, plain:float) -> float:
    return (compute_diff(fhe, plain) / plain) * 100

def compute_growth_percentage_dict(fhe:dict, plain:dict) -> dict:
    return {k: compute_growth_percentage(fhe[k], plain[k]) for k in fhe}

def verbose_md_table(pathToAssertion:str) -> Markdown:
    """
    Returns a markdown table with the similarity scores for each metric.
    """
    rows = []
    rows.append("Similarity (frameCount) | Score [%] | Mean FHE Absolute Error | Pre-processing (s) | Encryption (ms) | FHE Compute (ms) | Plaintext Compute (ms) | FHE/Plain Compute Growth (ms) [%]")
    rows.append("---|---|---|---|---|---|---|---")
    for frameCount in ['all', 'firstLast', 'randomHalf']:
        kld, bhattacharyya, cramer = mean_scores(pathToAssertion, frameCounts=[frameCount]).values()
        kld_perc, bhattacharyya_perc, cramer_perc = scores_as_normalized_percentage(kld, bhattacharyya, cramer).values()
        kld_err, bhattacharyya_err, cramer_err = mean_abs_errors(pathToAssertion, frameCounts=[frameCount]).values()

        pp = mean_pp_duration_s(pathToAssertion, frameCounts=[frameCount])

        kld_enc, bhattacharyya_enc, cramer_enc = mean_encryption_duration_ms(pathToAssertion, frameCounts=[frameCount]).values()
        kld_fhe, bhattacharyya_fhe, cramer_fhe = mean_fhe_compute_score_ms(pathToAssertion, frameCounts=[frameCount]).values()
        kld_pt, bhattacharyya_pt, cramer_pt = mean_pt_compute_score_ms(pathToAssertion, frameCounts=[frameCount]).values()

        _params = {
            'fhe': {'kld': kld_fhe, 'bhattacharyya': bhattacharyya_fhe, 'cramer': cramer_fhe},
            'plain': {'kld': kld_pt, 'bhattacharyya': bhattacharyya_pt, 'cramer': cramer_pt}
        }
        kld_diff, bhattacharyya_diff, cramer_diff = compute_diff_dict(**_params).values()
        kld_diff_perc, bhattacharyya_diff_perc, cramer_diff_perc = compute_growth_percentage_dict(**_params).values()

        rows.append(f"KLD ({frameCount}) | {kld:.2e} ({kld_perc:.2f}%) | {kld_err:.2e} | {pp:.2f} | {kld_enc:.2f} | {kld_fhe:.2f} | {kld_pt:.2f} | {kld_diff:.2f} [{kld_diff_perc:.2f}%]")
        rows.append(f"Cramer ({frameCount}) | {cramer:.2e} ({cramer_perc:.2f}%)| {cramer_err:.2e} | {pp:.2f} | {cramer_enc:.2f} | {cramer_fhe:.2f} | {cramer_pt:.2f} | {cramer_diff:.2f} [{cramer_diff_perc:.2f}%]")
        rows.append(f"BC ({frameCount}) | {bhattacharyya:.2e} ({bhattacharyya_perc:.2f}%) | {bhattacharyya_err:.2e} | {pp:.2f} | {bhattacharyya_enc:.2f} | {bhattacharyya_fhe:.2f} | {bhattacharyya_pt:.2f} | {bhattacharyya_diff:.2f} [{bhattacharyya_diff_perc:.2f}%]")

    return Markdown(textwrap.dedent('\n'.join(rows)))


def mean_md_table(pathToAssertion:str) -> Markdown: 
    """
    Returns a markdown table with the average of all assertions
    """
    kld, bhattacharyya, cramer = mean_scores(pathToAssertion).values()
    kld_perc, bhattacharyya_perc, cramer_perc = scores_as_normalized_percentage(kld, bhattacharyya, cramer).values()
    kld_err, bhattacharyya_err, cramer_err = mean_abs_errors(pathToAssertion).values()
    pp = mean_pp_duration_s(pathToAssertion)
    kld_enc, bhattacharyya_enc, cramer_enc = mean_encryption_duration_ms(pathToAssertion).values()

    kld_fhe, bhattacharyya_fhe, cramer_fhe = mean_fhe_compute_score_ms(pathToAssertion).values()
    kld_pt, bhattacharyya_pt, cramer_pt = mean_pt_compute_score_ms(pathToAssertion).values()
    _params = {
        'fhe': {'kld': kld_fhe, 'bhattacharyya': bhattacharyya_fhe, 'cramer': cramer_fhe},
        'plain': {'kld': kld_pt, 'bhattacharyya': bhattacharyya_pt, 'cramer': cramer_pt}
    }
    kld_diff, bhattacharyya_diff, cramer_diff = compute_diff_dict(**_params).values()
    kld_diff_perc, bhattacharyya_diff_perc, cramer_diff_perc = compute_growth_percentage_dict(**_params).values()

    return Markdown(textwrap.dedent(f"""
        Similarity | Mean Score [%] | Mean FHE Mean Absolute Error | Mean Pre-processing (s) | Mean Encryption (ms) | Mean FHE/Plain Compute Growth (ms) [%]
        ---|---|---|---|---|---
        KLD | {kld:.2e} ({kld_perc:.2f}%) | {kld_err:.2e} | {pp:.2f} | {kld_enc:.2f} | {kld_diff:.2f} [{kld_diff_perc:.2f}%]
        Cramer | {cramer:.2e} ({cramer_perc:.2f}%) | {cramer_err:.2e} | {pp:.2f} | {cramer_enc:.2f} | {cramer_diff:.2f} [{cramer_diff_perc:.2f}%]
        BC | {bhattacharyya:.2e} ({bhattacharyya_perc:.2f}%) | {bhattacharyya_err:.2e} | {pp:.2f} | {bhattacharyya_enc:.2f} | {bhattacharyya_diff:.2f} [{bhattacharyya_diff_perc:.2f}%]
    """))  

