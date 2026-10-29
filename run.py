"""Download (or verify), reproduce, extend, validate and plot. Stops on any failed check."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--offline', action='store_true', help='Require already downloaded inputs')
    args = parser.parse_args()
    if not shutil.which('Rscript'):
        parser.error('Rscript not found. Install R 4.6.0 and run Rscript setup.R from the project root.')
    start = time.monotonic()
    commands = [[sys.executable, 'code/check_project.py'],
                [sys.executable, 'code/fetch_data.py'] + (['--verify'] if args.offline else [])]
    commands += [['Rscript', f'code/{name}.R'] for name in
                 ['check_environment', 'reproduce', 'extend', 'validate_extension', 'figures']]
    env = os.environ.copy()
    env.update({'OMP_NUM_THREADS': '1', 'OPENBLAS_NUM_THREADS': '1', 'RCPP_PARALLEL_NUM_THREADS': '1'})
    for command in commands:
        print('\nRunning: ' + ' '.join(command), flush=True)
        subprocess.run(command, cwd=ROOT, env=env, check=True)
    print(f'\nPipeline completed in {time.monotonic()-start:.1f}s. Published R-squared still does not match; see results/r_squared_audit.csv.')


if __name__ == '__main__':
    main()
