
import subprocess
import sys

subprocess.run([
    sys.executable,
    '-m',
    'kaggle',
    'datasets',
    'download',
    '-d', 'olistbr/brazilian-ecommerce',
    '--unzip',
    '-p', './data/'
])