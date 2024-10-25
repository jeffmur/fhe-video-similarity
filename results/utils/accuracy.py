from utils.log import ImportSimilarityScores

def mean_scores(pathToAssertion:str, os, frameCounts) -> dict:
    """
    Returns the average of the similarity scores for each similarity score metric for the linux_sso logs.
    """
    kld_avg = bhattacharyya_avg = cramer_avg = 0
    for sys in os:
        for frameCount in frameCounts:
            linux_sso_logs = ImportSimilarityScores(f'{pathToAssertion}/{sys}_sso_{frameCount}.csv')

            kld_avg += linux_sso_logs.avg_scores("kld")
            bhattacharyya_avg += linux_sso_logs.avg_scores("bhattacharyya")
            cramer_avg += linux_sso_logs.avg_scores("cramer")

    return {
        'kld': kld_avg / (len(frameCounts) * len(os)),
        'bhattacharyya': bhattacharyya_avg / (len(frameCounts) * len(os)),
        'cramer': cramer_avg / (len(frameCounts) * len(os))
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

def mean_abs_errors(pathToAssertion:str, os, frameCounts) -> dict:
    """
    Returns the mean error for each similarity score metric for the linux_sso logs.
    """
    kld_err = bhattacharyya_err = cramer_err = 0
    for sys in os:
        for frameCount in frameCounts:
            linux_sso_logs = ImportSimilarityScores(f'{pathToAssertion}/{sys}_sso_{frameCount}.csv')

            kld_err += linux_sso_logs.score_diff("kld")
            bhattacharyya_err += linux_sso_logs.score_diff("bhattacharyya")
            cramer_err += linux_sso_logs.score_diff("cramer")

        return {
            'kld_err': kld_err / (len(frameCounts) * len(os)),
            'bhattacharyya_err': bhattacharyya_err / len(frameCounts),
            'cramer_err': cramer_err / len(frameCounts)
        }
