# AI
```
# fix docker
mkdir -p $HOME/.docker/{var,run}/docker
mkdir -p models/libretranslate && sudo chown 1032:1032 models/libretranslate
cat <<EOF | sudo tee /etc/docker/daemon.json
{ "data-root": "$HOME/.docker/lib/docker", "exec-root": "$HOME/.docker/run/docker" }
EOF
sudo systemctl restart docker docker.socket containerd.service
#sudo dnf install -y nvidia-container-toolkit
#sudo nvidia-ctk runtime configure --runtime=docker
#sudo systemctl restart docker docker.socket containerd.service
cd genAI/
# get models
# https://yelog.org/2024/10/10/install-ollama-offline-english/
mkdir -p ./models/ollama/gguf ./models/a1111/ckpt
# URL="https://huggingface.co/MaziyarPanahi/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct.Q8_0.gguf"
# curl -L "${URL}" -o ./models/ollama/gguf/"$(basename "${URL}")"
# URL="https://huggingface.co/MaziyarPanahi/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3.Q8_0.gguf"
# curl -L "${URL}" -o ./models/ollama/gguf/"$(basename "${URL}")"
# URL="https://huggingface.co/bartowski/Qwen2.5-Coder-32B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-32B-Instruct-Q8_0.gguf"
# curl -L "${URL}" -o ./models/ollama/gguf/"$(basename "${URL}")"
# URL="https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-32B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf"
# curl -L "${URL}" -o ./models/ollama/gguf/"$(basename "${URL}")"
# URL="https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-nonema-pruned.ckpt"
# curl -L "${URL}" -o ./models/a1111/ckpt/"$(basename "${URL}")"
# URL="https://raw.githubusercontent.com/Stability-AI/stablediffusion/main/configs/stable-diffusion/v2-inference-v.yaml"
# curl -L "${URL}" -o ./models/a1111/ckpt/v2-1_768-nonema-pruned.yaml
# URL="https://huggingface.co/stabilityai/stable-diffusion-2-depth/resolve/main/512-depth-ema.ckpt"
# curl -L "${URL}" -o ./models/a1111/ckpt/"$(basename "${URL}")"
# URL="https://github.com/Stability-AI/stablediffusion/raw/main/configs/stable-diffusion/v2-midas-inference.yaml"
# curl -L "${URL}" -o ./models/a1111/ckpt/512-depth-ema.yaml
# URL="https://github.com/intel-isl/DPT/releases/download/1_0/dpt_hybrid-midas-501f0c75.pt"
# curl -L "${URL}" -o ./models/a1111/ckpt/"$(basename "${URL}")"
# cp models/a1111/ckpt/dpt_hybrid-midas-501f0c75.pt a1111_fs/models/midas/dpt_hybrid-midas-501f0c75.pt
# URL="https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"
# curl -L "${URL}" -o ./models/a1111/ckpt/"$(basename "${URL}")"
# URL="https://raw.githubusercontent.com/Stability-AI/generative-models/refs/heads/main/configs/inference/sd_xl_base.yaml"
# curl -L "${URL}" -o ./models/a1111/ckpt/"$(basename "${URL}")"
# python -c 'from huggingface_hub import snapshot_download; snapshot_download(repo_id="openai/clip-vit-large-patch14", cache_dir="./models/a1111/ckpt")'
# cd ./models/a1111/ckpt/models--openai--clip-vit-large-patch14/ && cp snapshots/*/* . && cd -
# URL="https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/sd3.5_medium.safetensors"
# curl -L "${URL}" -o ./models/a1111/ckpt/"$(basename "${URL}")"
# URL="https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors"
# curl -L "${URL}" -o ./models/a1111/ckpt/"$(basename "${URL}")"
# pip3 install --user huggingface_hub
# python -c 'from huggingface_hub import snapshot_download; snapshot_download(repo_id="sentence-transformers/all-MiniLM-L6-v2", cache_dir="openwebui_fs/cache/embedding/models/")'
# python -c 'from huggingface_hub import snapshot_download; snapshot_download(repo_id="Systran/faster-whisper-base", cache_dir="openwebui_fs/cache/whisper/models/")'
# python -c 'from huggingface_hub import hf_hub_download; hf_hub_download(repo_id="black-forest-labs/FLUX.1-schnell", filename="flux1-schnell.safetensors", local_dir="./models/comfyui/checkpoints/")'
# python -c 'from huggingface_hub import hf_hub_download; hf_hub_download(repo_id="black-forest-labs/FLUX.1-schnell", filename="ae.safetensors", local_dir="./models/comfyui/vae/")'
# python -c 'from huggingface_hub import hf_hub_download; hf_hub_download(repo_id="comfyanonymous/flux_text_encoders", filename="clip_l.safetensors", local_dir="./models/comfyui/clip/")'
# python -c 'from huggingface_hub import hf_hub_download; hf_hub_download(repo_id="comfyanonymous/flux_text_encoders", filename="t5xxl_fp16.safetensors", local_dir="./models/comfyui/clip/")'
# mkdir -p ./models/comfyui/unet && cp ./models/comfyui/checkpoints/flux1-*.safetensors ./models/comfyui/unet
## sudo systemctl start docker
## sudo usermod -aG docker $USER
## newgrp docker
## docker run hello-world
## docker system prune --all --force --volumes
rm -f .env && ln -s env.desktop .env
CF="genai-docker-compose.yaml"
CFG="genai-docker-compose.nvidia-override.yaml"
PODM=('--podman-run-args' '--cgroup-manager cgroupfs')
PODMN=('--cgroup-manager' 'cgroupfs')
PODMNN=('--disable-dns')
COMFYUI_WORKFLOW_MODEL="v1-5-pruned-emaonly-fp16.safetensors"
sed -i -e "s@xxxCOMFYUI_WORKFLOW_MODELxxx@${COMFYUI_WORKFLOW_MODEL}@g" -e "s@xxxCOMFYUI_WORKFLOWxxx@$(echo $(cat "comfyui_fs/${COMFYUI_WORKFLOW_MODEL}.json"))@g" .env
#for v1-5  -> in Settings->Images: Prompt=6, Model=4, Width=5, Hight=5, Steps=3, Seed=3
#for flux  -> in Settings->Images: Prompt=6, Model=30, Width=27, Hight=27, Steps=31, Seed=31
docker ${PODMN[@]} network create ${PODMNN[@]} genai-public-net
docker ${PODMN[@]} network create ${PODMNN[@]} genai-private-net
for SERV in openwebui-dl libretranslate-dl ollama-dl vllm-dl comfyui-dl openedaispeech-dl; do
  #docker compose ${PODM[@]} -f "${CF}" --profile dl run "${SERV}"
  docker compose ${PODM[@]} -f "${CF}" build "${SERV}"
  docker compose ${PODM[@]} -f "${CF}" run "${SERV}"
done
#TMP=/media/games/docker/tmp docker compose -f "${CF}" up --remove-orphans
docker compose -f "${CF}" up --remove-orphans --detach
#docker compose -f "${CF}" -f "${CFG}" build comfyui
#docker compose -f "${CF}" -f "${CFG}" up --remove-orphans --detach
#docker compose -f "${CF}" down
#docker network rm genai-public-net genai-private-net
## for podman : docker compose --podman-args '--cgroup-manager cgroupfs' ...
#
# first boot
open http://127.0.0.1:11080/
create admin user: admin, a@b.com, <somePW>
-> go to 'Admin Panel'
-->> go to 'Settings'
--->>> in 'General' enable 'Enable New Sign Ups'
import translate function
-> go to 'Admin Panel'
-->> go to 'Functions'
-->> 'Import Functions' -> select from libretranslate_fs -> Enable and Enable Global -> Valves -> change 'default' to http://libretranslate:5000
#
# register new models in ollama
# eg. params and template content from: https://ollama.com/library/llama3.1:8b
# pip3 install --user html2text
# tempale: curl https://ollama.com/library/llama3.1:8b/blobs/948af2743fc7 | sed -n '/^  <div class="$/,/^<\/div>$/p' && html2text 1.html && html2text 1.html
# parameter: curl https://ollama.com/library/deepseek-r1:32b/blobs/f4d24e9138dd | sed -n '/^  <div class="$/,/^<\/div>$/p' | sed -e '/^$/d' >1.html && html2text 1.html | /bin/grep '^"<'
ls models/ollama/gguf/*.gguf | while IFS= read -r M; do
    cat <<EOF > models/ollama/gguf/"$(basename "${M%.*}")"
FROM ./$(basename "${M}")
TEMPLATE """@STUFF HERE@
"""
SYSTEM """"""
PARAMETER stop @AND...       #<|im_start|>
PARAMETER stop  ...HERE...@  #<|im_end|>
EOF
done
ls models/ollama/gguf/*.gguf | while IFS= read -r M; do
    MN="$(basename "${M%.*}")"
    docker exec ollama ollama create "${MN}" -f /gguf/"${MN}"
done; docker exec ollama ollama list
#
#OLLAMA_DEFAULT_MODEL="snowflake-arctic-embed:22m" \
#docker compose -f "${CF}" --profile dl run --remove-orphans ollama-dl
OLLAMA_DEFAULT_MODEL="all" \
docker compose -f "${CF}" --profile dl run --remove-orphans ollama-dl
#
# DL voice model
#OPENEDAISPEECH_DEFAULT_VOICE=en_GB-alba-medium docker compose -f "${CF}" --profile dl run --remove-orphans openedaispeech-dl
#sudo sed -i -e '/tts-1:/a\  en_GB-alba-medium:\n    model: voices/en_GB-alba-medium.onnx\n    speaker: # default speaker' openedaispeech_fs/voice_to_speaker.yaml
#
# ssl
#scp $HOME/Documents/RIKEN/SuPeR/C100/server.cert/R* /root/genAI/nginx_fs/ssl/
#cat nginx_fs/ssl/RIKEN-R-CCS-SPRTeam-servers.crt.pem nginx_fs/ssl/RIKEN-R-CCS-SPRTeam.ca.crt > nginx_fs/ssl/fullchain.pem
#cat nginx_fs/ssl/RIKEN-R-CCS-SPRTeam-servers.key.pem > nginx_fs/ssl/privkey.pem
#sed -i -e 's@#listen 443@listen 443@g' -e 's@#ssl_@ssl_@g' nginx_fs/nginx.conf
```

podman
```
chcon -t container_file_t *_fs/download_models.sh
loginctl enable-linger $(whoami)
mkdir -p ~/.config/containers /tmp/$(whoami)/containers/storage
cat <<EOF > ~/.config/containers/storage.conf
[storage]
driver="overlay"
#runroot = "/tmp/$(whoami)/containers/storage"
runroot = "/run/user/$(id -u)/containers/storage"
graphroot = "/tmp/$(whoami)/containers/storage"
rootless_storage_path="/tmp/$(whoami)/containers/storage"
[storage.options]
mount_program = "/usr/bin/fuse-overlayfs"
[storage.options.overlay]
mountopt="xattr_permissions=2,threaded=1"
EOF
docker run hello-world
```
