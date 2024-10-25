import textwrap, os
from IPython.display import Markdown
from utils.accuracy import *
from utils.performance import *
from utils import TARGET_SYS, FRAME_COUNTS

def compute_diff(fhe:float, plain:float) -> float:
    return abs(fhe - plain)

def compute_diff_dict(fhe:dict, plain:dict) -> dict:
    return {k: compute_diff(fhe[k], plain[k]) for k in fhe}

def compute_growth_percentage(fhe:float, plain:float) -> float:
    return (compute_diff(fhe, plain) / plain) * 100

def compute_growth_percentage_dict(fhe:dict, plain:dict) -> dict:
    return {k: compute_growth_percentage(fhe[k], plain[k]) for k in fhe}

def compute_metrics(pathToAssertion:str, os=TARGET_SYS, frameCounts=FRAME_COUNTS) -> dict:
    """
    Returns a dictionary with data for each metric.
    """
    kld, bhattacharyya, cramer = mean_scores(pathToAssertion, os, frameCounts).values()
    kld_perc, bhattacharyya_perc, cramer_perc = scores_as_normalized_percentage(kld, bhattacharyya, cramer).values()
    kld_err, bhattacharyya_err, cramer_err = mean_abs_errors(pathToAssertion, os, frameCounts).values()

    pp = mean_pp_duration_s(pathToAssertion, os, frameCounts)

    kld_enc, bhattacharyya_enc, cramer_enc = mean_encryption_duration_ms(pathToAssertion, os, frameCounts).values()
    kld_fhe, bhattacharyya_fhe, cramer_fhe = mean_fhe_compute_score_ms(pathToAssertion, os, frameCounts).values()
    kld_pt, bhattacharyya_pt, cramer_pt = mean_pt_compute_score_ms(pathToAssertion, os, frameCounts).values()

    _params = {
        'fhe': {'kld': kld_fhe, 'bhattacharyya': bhattacharyya_fhe, 'cramer': cramer_fhe},
        'plain': {'kld': kld_pt, 'bhattacharyya': bhattacharyya_pt, 'cramer': cramer_pt}
    }
    kld_diff, bhattacharyya_diff, cramer_diff = compute_diff_dict(**_params).values()
    kld_diff_perc, bhattacharyya_diff_perc, cramer_diff_perc = compute_growth_percentage_dict(**_params).values()

    return {
        'kld': {'score': kld, 'score_perc': kld_perc, 'err': kld_err, 'pp': pp, 'enc': kld_enc, 'fhe': kld_fhe, 'pt': kld_pt, 'diff': kld_diff, 'diff_perc': kld_diff_perc},
        'bhattacharyya': {'score': bhattacharyya, 'score_perc': bhattacharyya_perc, 'err': bhattacharyya_err, 'pp': pp, 'enc': bhattacharyya_enc, 'fhe': bhattacharyya_fhe, 'pt': bhattacharyya_pt, 'diff': bhattacharyya_diff, 'diff_perc': bhattacharyya_diff_perc},
        'cramer': {'score': cramer, 'score_perc': cramer_perc, 'err': cramer_err, 'pp': pp, 'enc': cramer_enc, 'fhe': cramer_fhe, 'pt': cramer_pt, 'diff': cramer_diff, 'diff_perc': cramer_diff_perc}
    }

def _verbose_md_row(metric:str, os:str, frameCount:str, data:dict):
    return f"{metric} [{os}] [{frameCount}] | {data['score']:.2e} [{data['score_perc']:.2f}%] | {data['err']:.2e} | {data['pp']:.2f} | {data['enc']:.2f} | {data['fhe']:.2f} | {data['pt']:.2f} | {data['diff']:.2f} [{data['diff_perc']:.2f}%]"

def verbose_md_table(pathToAssertion:str, sys=TARGET_SYS, frameCounts=FRAME_COUNTS) -> Markdown:
    """
    Returns a markdown table with the similarity scores for each metric.
    """
    rows = []
    rows.append("Similarity [sys] [frameCount] | Score [%] | Mean FHE Absolute Error | Pre-processing (s) | Encryption (ms) | FHE Compute (ms) | Plaintext Compute (ms) | FHE/Plain Compute Growth (ms) [%]")
    rows.append("---|---|---|---|---|---|---|---")
    for s in sys:
        if not any(pre.startswith(s) for pre in os.listdir(pathToAssertion)): continue
        for f in frameCounts:
            kld, bhattacharyya, cramer = compute_metrics(pathToAssertion, [s], [f]).values()
            rows.append(_verbose_md_row('KLD', s, f, kld))
            rows.append(_verbose_md_row('Cramer', s, f, cramer))
            rows.append(_verbose_md_row('BC', s, f, bhattacharyya))

    return Markdown(textwrap.dedent('\n'.join(rows)))

def _mean_md_row(metric:str, os:str, data:dict):
    return f"{metric} [{os}] | {data['score']:.2e} [{data['score_perc']:.2f}%] | {data['err']:.2e} | {data['pp']:.2f} | {data['enc']:.2f} | {data['diff']:.2f} [{data['diff_perc']:.2f}%]"

def mean_md_table(pathToAssertion:str, sys=TARGET_SYS, frameCounts=FRAME_COUNTS) -> Markdown: 
    """
    Returns a markdown table with the average of all assertions
    """
    rows = []
    rows.append("Similarity [sys] | Score [%] | Mean Absolute Error | Pre-processing (s) | Encryption (ms) | FHE/Plain Compute Growth (ms) [%]")
    rows.append("---|---|---|---|---|---")
    for s in sys:
        if not any(pre.startswith(s) for pre in os.listdir(pathToAssertion)): continue
        kld, bhattacharyya, cramer = compute_metrics(pathToAssertion, [s], frameCounts).values()
        rows.append(_mean_md_row('KLD', s, kld))
        rows.append(_mean_md_row('Cramer', s, cramer))
        rows.append(_mean_md_row('BC', s, bhattacharyya))

    return Markdown(textwrap.dedent('\n'.join(rows)))