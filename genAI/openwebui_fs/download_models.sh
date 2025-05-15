#!/bin/bash
pip3 install huggingface_hub

[ ! -d /app/backend/data/cache/embedding/models/models--sentence-transformers--all-MiniLM-L6-v2 ] && python3 -c 'from huggingface_hub import snapshot_download; snapshot_download(repo_id="sentence-transformers/all-MiniLM-L6-v2", cache_dir="/app/backend/data/cache/embedding/models/")'

[ ! -d /app/backend/data/cache/whisper/models/models--Systran--faster-whisper-base ] && python3 -c 'from huggingface_hub import snapshot_download; snapshot_download(repo_id="Systran/faster-whisper-base", cache_dir="/app/backend/data/cache/whisper/models/")'
