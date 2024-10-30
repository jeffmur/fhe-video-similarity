import os
from utils.log import ImportSimilarityScores

def mean_scores(pathToAssertion:str, sys, frameCounts) -> dict:
    """
    Returns the average of the similarity scores for each similarity score metric for the linux_sso logs.
    """
    kld_avg = bhattacharyya_avg = cramer_avg = 0
    for s in sys:
        for frameCount in frameCounts:
            if not any(pre.startswith(s) for pre in os.listdir(pathToAssertion)): continue
            linux_sso_logs = ImportSimilarityScores(f'{pathToAssertion}/{s}_sso_{frameCount}.csv')

            kld_avg += linux_sso_logs.avg_scores("kld")
            bhattacharyya_avg += linux_sso_logs.avg_scores("bhattacharyya")
            cramer_avg += linux_sso_logs.avg_scores("cramer")

    return {
        'kld': kld_avg / (len(frameCounts) * len(sys)),
        'bhattacharyya': bhattacharyya_avg / (len(frameCounts) * len(sys)),
        'cramer': cramer_avg / (len(frameCounts) * len(sys))
    }

def scores_as_normalized_percentage(kld:float, bhattacharyya:float, cramer:float) -> dict:
    """
    Normalizes the similarity scores as a percentage.
    """
    return {
        'kld_perc': (1 / (1 + kld)) * 100,
        'cramer': (1 - abs(cramer)) * 100,
        'bhattacharyya': bhattacharyya * 100,
    }

def mean_abs_errors(pathToAssertion:str, sys, frameCounts) -> dict:
    """
    Returns the absolute mean error for each similarity score metric for the linux_sso logs.
    """
    kld_err = bhattacharyya_err = cramer_err = 0
    for s in sys:
        for frameCount in frameCounts:
            if not any(pre.startswith(s) for pre in os.listdir(pathToAssertion)): continue
            linux_sso_logs = ImportSimilarityScores(f'{pathToAssertion}/{s}_sso_{frameCount}.csv')

            kld_err += linux_sso_logs.score_mean_error("kld")
            bhattacharyya_err += linux_sso_logs.score_mean_error("bhattacharyya")
            cramer_err += linux_sso_logs.score_mean_error("cramer")

        return {
            'kld_err': kld_err / (len(frameCounts) * len(sys)),
            'bhattacharyya_err': bhattacharyya_err / len(frameCounts),
            'cramer_err': cramer_err / len(frameCounts)
        }
