#!/bin/bash
pip3 install huggingface_hub

[ ! -e /models/checkpoints/v1-5-pruned-emaonly-fp16.safetensors ] && python3 -c 'from huggingface_hub import hf_hub_download; hf_hub_download(repo_id="Comfy-Org/stable-diffusion-v1-5-archive", filename="v1-5-pruned-emaonly-fp16.safetensors", local_dir="/models/checkpoints/")'

[ ! -e /models/checkpoints/flux1-schnell-fp8.safetensors ] && python3 -c 'from huggingface_hub import hf_hub_download; hf_hub_download(repo_id="Comfy-Org/flux1-schnell", filename="flux1-schnell-fp8.safetensors", local_dir="/models/checkpoints/")'  #this is a premade chkpt and not a raw diffusion_model

#[ ! -e /models/checkpoints/sd3.5_medium_incl_clips_t5xxlfp8scaled.safetensors ] && python3 -c 'from huggingface_hub import hf_hub_download; hf_hub_download(repo_id="Comfy-Org/stable-diffusion-3.5-fp8", filename="sd3.5_medium_incl_clips_t5xxlfp8scaled.safetensors", local_dir="/models/checkpoints/")'

#[ ! -e /models/diffusion_models/flux1-schnell.safetensors ] && python3 -c 'from huggingface_hub import hf_hub_download; hf_hub_download(repo_id="black-forest-labs/FLUX.1-schnell", filename="flux1-schnell.safetensors", local_dir="/models/diffusion_models/")'

[ ! -e /models/vae/ae.safetensors ] && python3 -c 'from huggingface_hub import hf_hub_download; hf_hub_download(repo_id="black-forest-labs/FLUX.1-schnell", filename="ae.safetensors", local_dir="/models/vae/")'

[ ! -e /models/clip/clip_l.safetensors ] && python3 -c 'from huggingface_hub import hf_hub_download; hf_hub_download(repo_id="comfyanonymous/flux_text_encoders", filename="clip_l.safetensors", local_dir="/models/clip/")'

[ ! -e /models/clip/t5xxl_fp16.safetensors ] && python3 -c 'from huggingface_hub import hf_hub_download; hf_hub_download(repo_id="comfyanonymous/flux_text_encoders", filename="t5xxl_fp16.safetensors", local_dir="/models/clip/")'

[ ! -e /models/unet/flux1-schnell.safetensors ] && mkdir -p /models/unet && cd /models/unet && ln -s ../diffusion_models/flux1-schnell.safetensors .
