"""Check required public project inputs, without network."""
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    rows = list(csv.DictReader((ROOT / 'data/published_targets.csv').open()))
    assert len(rows) == 14 and len({(r['model'], r['term']) for r in rows}) == 14
    assert {r['model'] for r in rows} == {'col1', 'col2', 'col4', 'col5'}
    for name in ['LICENSE', 'renv.lock', 'data/sources.json', 'README.md', 'setup.R', 'run.py']:
        assert (ROOT / name).is_file(), name
    for name in ['model.R', 'reproduce.R', 'extend.R', 'validate_extension.R', 'figures.R',
                 'check_environment.R', 'fetch_data.py']:
        assert (ROOT / 'code' / name).is_file(), name
    print('Required project inputs verified.')


if __name__ == '__main__':
    main()
