#!/usr/bin/env python3
import argparse
import tarfile
from pathlib import Path

REQUIRED = [
    'public/index.php',
    'config/app.php',
    'config/routes.php',
    'app/Core/Database.php',
    'database/01_esquema.sql',
]

def main() -> int:
    parser = argparse.ArgumentParser(description='Verifica paquete de finanzas-personales')
    parser.add_argument('archive', type=Path, help='Ruta al .tar.gz generado')
    args = parser.parse_args()

    if not args.archive.is_file():
      print('VERIFY_FAIL=archive_not_found')
      return 1

    with tarfile.open(args.archive, 'r:gz') as tar:
        names = set(tar.getnames())

    missing = [item for item in REQUIRED if item not in names and f'./{item}' not in names]
    if missing:
        print('VERIFY_FAIL=missing_files')
        for item in missing:
            print(f'MISSING={item}')
        return 1

    print('VERIFY_OK=1')
    print(f'ARCHIVE={args.archive}')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
