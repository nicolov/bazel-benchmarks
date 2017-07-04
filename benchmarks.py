#!/usr/bin/env python

from __future__ import print_function

import json
import os
from subprocess import check_call, check_output
import sys

import click
import stopwatch


GIT_REPO_PATH = '/tmp/build'
GIT_REPO_URL = 'https://github.com/RobotLocomotion/drake.git'
# Two random revisions of the code, ~ 1 week apart
GIT_REV_OLD = '290724e'
GIT_REV_NEW = '60b5ed9'


def _get_timings(sw):
    " Output stopwatch timings in JSON format. """
    report = sw.get_last_aggregated_report()
    values = report.aggregated_values

    # fetch all values only for main stopwatch, ignore all the tags
    log_names = sorted(
        log_name for log_name in values if "+" not in log_name
    )
    if not log_names:
        return

    data = {}

    for log_name in log_names[1:]:
        delta_ms, count, bucket = values[log_name]
        short_name = log_name[log_name.rfind("#") + 1:]
        data[short_name] = delta_ms

    return data


def _sh(cmd, *args, **kwargs):
    return check_call(cmd, *args, shell=True, **kwargs)


#

def _checkout_code(revision):
    if not os.path.exists(GIT_REPO_PATH):
        _sh('git clone {} {}'.format(GIT_REPO_URL, GIT_REPO_PATH))
    _sh('git checkout {}'.format(revision), cwd=GIT_REPO_PATH)


def _build():
    # target = '//...'  # ~30m
    target = '//drake/examples:simple_continuous_time_system'  # ~30s
    # target = '//drake/examples/QPInverseDynamicsForHumanoids/system:valkyrie_controller'  # ~5m
    _sh('bazel build {} --compiler=clang-3.9 --verbose_failures'.format(target),
        cwd=GIT_REPO_PATH)


def _clean():
    if os.path.exists(GIT_REPO_PATH):
        _sh('bazel clean --expunge', cwd=GIT_REPO_PATH)


def _enable_cache():
    """ Write .bazelrc to enable remote caching. """
    bazelrc_path = os.path.join(GIT_REPO_PATH, '.bazelrc')

    with open(bazelrc_path, 'w') as f:
        f.write("""
startup --host_jvm_args=-Dbazel.DigestFunction=SHA1
build --spawn_strategy=remote
build --remote_rest_cache=http://cacher:7070/cache""")


@click.group()
def cli():
    pass


@cli.command()
@click.option('--enable-cache', is_flag=True)
def between_commits(enable_cache):
    """ Benchmark builds going back and forth between two
    commits. """

    _clean()
    _checkout_code(GIT_REV_OLD)

    if enable_cache:
        _enable_cache()

    # Count the number of lines in the diff
    num_diff_lines = check_output(
        'git diff {} {} | wc -l'.format(GIT_REV_OLD, GIT_REV_NEW),
        shell=True,
        cwd=GIT_REPO_PATH).strip()

    sw = stopwatch.StopWatch()

    with sw.timer('between_commits'):
        with sw.timer('1_clean_build_old'):
            _build()
        with sw.timer('2_no_op_build'):
            _build()
        
        # Jump to the newer commit and build again
        _checkout_code(GIT_REV_NEW)
        with sw.timer('3_build_new_commit'):
            _build()
        with sw.timer('4_no_op_build'):
            _build()
        
        # Revert to the old one and build again
        _checkout_code(GIT_REV_OLD)
        with sw.timer('5_build_old_again'):
            _build()

    # Save and print results
    timings_data = _get_timings(sw)
    output_fname = 'timings_cache_{}.json'.format(enable_cache)
    with open(output_fname, 'w') as f:
        json.dump(timings_data, f, indent=2)
        print(json.dumps(timings_data, indent=2))

    print('{} diff lines between commits {} and {}'.format(
        num_diff_lines, GIT_REV_OLD, GIT_REV_NEW))


if __name__ == '__main__':
    cli()
