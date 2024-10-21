from utils.csv import CompareAllScores
import textwrap, matplotlib.pyplot as plt
from IPython.display import Markdown
import numpy as np

def verbose_kld_cramer(pathToDir:str):
    "Compare the KLD and Cramer scores for Dart and SSO for broken down for each csv file"
    s = CompareAllScores(pathToDir)
    rows = []
    rows.append("File | KLD SSO σ | KLD Dart σ | KLD ± σ | KLD JC | KLD CS | Cramer SSO σ | Cramer Dart σ | Cramer ± σ | Cramer JC | Cramer CS")
    rows.append("---|---|---|---|---|---|---|---|---|---|---")
    for file in s.scores.keys():
        ss = s.scores[file]
        kldDart_stdev = ss.standard_deviation(ss.kldDart)
        kldSSO_stdev = ss.standard_deviation(ss.kldSSO)
        abs_diff_kld = abs(kldDart_stdev - kldSSO_stdev)
        kld_jaccard = ss.jaccard_coefficent(ss.kldDart, ss.kldSSO)
        kld_cosine = ss.cosine_similarity(ss.kldDart, ss.kldSSO)

        cramerDart_stdev = ss.standard_deviation(ss.cramerDart)
        cramerSSO_stdev = ss.standard_deviation(ss.cramerSSO)
        abs_diff_cramer = abs(cramerDart_stdev - cramerSSO_stdev)
        cramer_jaccard = ss.jaccard_coefficent(ss.cramerDart, ss.cramerSSO)
        cramer_cosine = ss.cosine_similarity(ss.cramerDart, ss.cramerSSO)

        rows.append(f"{file} | {kldSSO_stdev:.6f} | {kldDart_stdev:.6f} | {abs_diff_kld:.6f} | {kld_jaccard:.2f} | {kld_cosine:.2f}"
                    f"| {cramerSSO_stdev:.6f} | {cramerDart_stdev:.6f} | {abs_diff_cramer:.6f} | {cramer_jaccard:.2f} | {cramer_cosine:.2f}")

    return Markdown(textwrap.dedent('\n'.join(rows)))

def summary_kld_cramer(pathToDir:str):
    "Compare the KLD and Cramer scores for Dart and SSO for all csv files"
    s = CompareAllScores(pathToDir)
    kldDart_stdev, kldSSO_stdev, cramerDart_stdev, cramerSSO_stdev = s.avg_standard_deviation().values()
    kld_jaccard, sso_jaccard = s.avg_jaccard_coefficent().values()
    kld_cosine, cramer_cosine = s.avg_cosine_similarity().values()
    rows = []
    rows.append("Algorithm | Dart σ | SSO σ | Avg. Jaccard Coefficient | Avg. Cosine Similarity")
    rows.append("---|---|---|---|---")
    rows.append(f"KLD | {kldDart_stdev:.6f} | {kldSSO_stdev:.6f} | {kld_jaccard:.2f} | {kld_cosine:.2f}")
    rows.append(f"Cramer | {cramerDart_stdev:.6f} | {cramerSSO_stdev:.6f} | {sso_jaccard:.2f} | {cramer_cosine:.2f}")

    return Markdown(textwrap.dedent('\n'.join(rows)))

def plot_kld_cramer_bar_chart(pathToDir:str):
    s = CompareAllScores(pathToDir)
    kldDart_stdev, kldSSO_stdev, cramerDart_stdev, cramerSSO_stdev = s.avg_standard_deviation().values()

    # Labels for the metric pairs
    labels = ['Kullback-Leibler Divergence', 'Cramer Distance']

    # Values for KLD and Cramer
    dart = [kldDart_stdev, cramerDart_stdev]
    sso = [kldSSO_stdev, cramerSSO_stdev]

    # Creating figure and axes
    fig, ax = plt.subplots()

    # Setting the positions for the groups
    x = np.arange(len(labels))  # label locations

    # Width of the bars
    width = 0.35

    # Plotting the bars for Dart and SSO separately but next to each other
    ax.bar(x - width/2, dart, width, label='Dart')
    ax.bar(x + width/2, sso, width, label='SSO')

    # Adding some text for labels, title and axes ticks
    ax.set_xlabel('Algorithms')
    ax.set_ylabel('Scores')
    ax.set_title('Comparison of Similarity Metrics')
    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.legend()

    # Display the plot
    plt.show()
