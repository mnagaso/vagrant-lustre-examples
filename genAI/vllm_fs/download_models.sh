#!/bin/bash
pip3 install huggingface_hub

#https://docs.vllm.ai/en/latest/models/supported_models.html

[ ! -d /root/.cache/huggingface/hub/models--"$(echo "${1}" | cut -d'/' -f1)"--"$(echo "${1}" | cut -d'/' -f2)" ] && python3 -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id=\"$(echo "${1}" | awk '{$1=$1};1')\", cache_dir=\"/root/.cache/huggingface/hub/\")"

#[ ! -d /root/.cache/huggingface/hub/models--facebook--MobileLLM-600M ] && python3 -c 'from huggingface_hub import snapshot_download; snapshot_download(repo_id="facebook/MobileLLM-600M", cache_dir="/root/.cache/huggingface/hub/")'

#[ ! -d /root/.cache/huggingface/hub/models--allenai--OLMo-1B-hf ] && python3 -c 'from huggingface_hub import snapshot_download; snapshot_download(repo_id="allenai/OLMo-1B-hf", cache_dir="/root/.cache/huggingface/hub/")'

#[ ! -d /root/.cache/huggingface/hub/models--microsoft--Phi-3-mini-4k-instruct ] && python3 -c 'from huggingface_hub import snapshot_download; snapshot_download(repo_id="microsoft/Phi-3-mini-4k-instruct", cache_dir="/root/.cache/huggingface/hub/")'

#[ ! -d /root/.cache/huggingface/hub/models--Qwen--Qwen2-7B ] && python3 -c 'from huggingface_hub import snapshot_download; snapshot_download(repo_id="Qwen/Qwen2-7B", cache_dir="/root/.cache/huggingface/hub/")'
