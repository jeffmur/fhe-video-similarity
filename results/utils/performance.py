import os
from utils.log import ImportSimilarityScores

def mean_pp_duration_s(pathToAssertion:str, sys, frameCounts) -> float:
    """
    Returns the average of the duration, in seconds, for each similarity score metric for the linux_sso logs.
    """
    pre_processing_avg = 0
    for s in sys:
        for frameCount in frameCounts:
            if not any(pre.startswith(s) for pre in os.listdir(pathToAssertion)): continue
            linux_sso_logs = ImportSimilarityScores(f'{pathToAssertion}/{s}_sso_{frameCount}.csv')

            pre_processing_avg += linux_sso_logs.pp_duration_s(frameCount)
    
    return pre_processing_avg / (len(frameCounts) * len(sys))

def mean_encryption_duration_ms(pathToAssertion:str, sys, frameCounts) -> dict:
    """
    Returns the average of the duration, in milliseconds, for each similarity score metric for the linux_sso logs.
    """
    kld_enc = bhattacharyya_enc = cramer_enc = 0
    for s in sys:
        for frameCount in frameCounts:
            if not any(pre.startswith(s) for pre in os.listdir(pathToAssertion)): continue
            linux_sso_logs = ImportSimilarityScores(f'{pathToAssertion}/{s}_sso_{frameCount}.csv')

            kld_enc += linux_sso_logs.encryption_duration_ms("kld")
            bhattacharyya_enc += linux_sso_logs.encryption_duration_ms("bhattacharyya")
            cramer_enc += linux_sso_logs.encryption_duration_ms("cramer")

    return {
        'kld_enc': kld_enc / (len(frameCounts) * len(sys)),
        'bhattacharyya_enc': bhattacharyya_enc / (len(frameCounts) * len(sys)),
        'cramer_enc': cramer_enc / (len(frameCounts) * len(sys))
    }

def mean_decryption_duration_ms(pathToAssertion:str, sys, frameCounts) -> dict:
    """
    Returns the average of the duration, in milliseconds, for each similarity score metric for the linux_sso logs.
    """
    kld_dec = bhattacharyya_dec = cramer_dec = 0
    for s in sys:
        for frameCount in frameCounts:
            if not any(pre.startswith(s) for pre in os.listdir(pathToAssertion)): continue
            linux_sso_logs = ImportSimilarityScores(f'{pathToAssertion}/{s}_sso_{frameCount}.csv')

            kld_dec += linux_sso_logs.decryption_duration_ms("kld")
            bhattacharyya_dec += linux_sso_logs.decryption_duration_ms("bhattacharyya")
            cramer_dec += linux_sso_logs.decryption_duration_ms("cramer")

    return {
        'kld_dec': kld_dec / (len(frameCounts) * len(sys)),
        'bhattacharyya_dec': bhattacharyya_dec / (len(frameCounts) * len(sys)),
        'cramer_dec': cramer_dec / (len(frameCounts) * len(sys))
    }


def mean_fhe_compute_score_ms(pathToAssertion:str, sys, frameCounts):
    """
    Returns the average of the duration, in milliseconds, for each similarity score metric for the linux_sso logs.
    """
    kld_fhe = bhattacharyya_fhe = cramer_fhe = 0
    for s in sys:
        for frameCount in frameCounts:
            if not any(pre.startswith(s) for pre in os.listdir(pathToAssertion)): continue
            linux_sso_logs = ImportSimilarityScores(f'{pathToAssertion}/{s}_sso_{frameCount}.csv')

            kld_fhe += linux_sso_logs.fhe_compute_score_ms("kld")
            bhattacharyya_fhe += linux_sso_logs.fhe_compute_score_ms("bhattacharyya")
            cramer_fhe += linux_sso_logs.fhe_compute_score_ms("cramer")

    return {
        'kld_fhe': kld_fhe / (len(frameCounts) * len(sys)),
        'bhattacharyya_fhe': bhattacharyya_fhe / (len(frameCounts) * len(sys)),
        'cramer_fhe': cramer_fhe / (len(frameCounts) * len(sys))
    }

def mean_pt_compute_score_ms(pathToAssertion:str, sys, frameCounts):
    """
    Returns the average of the duration, in milliseconds, for each similarity score metric for the linux_sso logs.
    """
    kld_pt = bhattacharyya_pt = cramer_pt = 0
    for s in sys:
        for frameCount in frameCounts:
            if not any(pre.startswith(s) for pre in os.listdir(pathToAssertion)): continue
            linux_sso_logs = ImportSimilarityScores(f'{pathToAssertion}/{s}_sso_{frameCount}.csv')

            kld_pt += linux_sso_logs.pt_compute_score_ms("kld")
            bhattacharyya_pt += linux_sso_logs.pt_compute_score_ms("bhattacharyya")
            cramer_pt += linux_sso_logs.pt_compute_score_ms("cramer")

    return {
        'kld_pt': kld_pt / (len(frameCounts) * len(sys)),
        'bhattacharyya_pt': bhattacharyya_pt / (len(frameCounts) * len(sys)),
        'cramer_pt': cramer_pt / (len(frameCounts) * len(sys))
    }
