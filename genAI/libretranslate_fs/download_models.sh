#!/bin/bash
[ -z "${1}" ] && exit

source venv/bin/activate
python3 scripts/install_models.py --load_only_lang_codes "${1}"
