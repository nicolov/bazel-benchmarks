#!/usr/bin/env python

import json

import click
from IPython import embed
from matplotlib import pyplot as plt
import pandas as pd
import seaborn as sns


def df_from_file(json_path, label):
    """ Load timings json data into a pd.DataFrame. """
    with open(json_path) as json_f:
        data = json.load(json_f)

    df = pd.DataFrame.from_dict(data, orient='index')
    df.columns = [label]
    df[label] /= 1000
    df = df.sort_index()

    return df


@click.command()
@click.option('--with-cache', is_flag=True)
def main(with_cache):
    df = df_from_file('timings_cache_False.json', 'no_cache')

    if with_cache:
        # Load and merge data from the no-cache case
        df2 = df_from_file('timings_cache_True.json', 'with_cache')
        df = df.merge(df2, left_index=True, right_index=True)

    ax = df.plot(kind='bar',
        legend=with_cache,
        figsize=(6,4),
        rot=45,)
    ax.figure.subplots_adjust(bottom=0.35)
    ax.set_ylabel('Time [s]')
    plt.tight_layout()

    output_file_name = 'results_with_cache.png' \
        if with_cache \
        else 'results_without_cache.png'
    ax.figure.savefig(output_file_name)


if __name__ == '__main__':
    main()
