#!/bin/bash
# setup_genai.sh - Script to automate genAI environment setup based on README.md instructions
set -e

# Fix Docker directories and permissions
echo "Setting up Docker directories and permissions..."
mkdir -p "$HOME/.docker/var/docker" "$HOME/.docker/run/docker"
mkdir -p models/libretranslate
sudo chown 1032:1032 models/libretranslate

# Configure Docker daemon
cat <<EOF | sudo tee /etc/docker/daemon.json
{ "data-root": "$HOME/.docker/lib/docker", "exec-root": "$HOME/.docker/run/docker" }
EOF

# Try to restart Docker service if it exists
if systemctl list-units --type=service | grep -qE 'docker(\.service)?'; then
  sudo systemctl restart docker docker.socket containerd.service || true
elif systemctl --user list-units --type=service | grep -qE 'docker(\.service)?'; then
  systemctl --user restart docker || true
else
  echo "Warning: Docker service not found, skipping restart."
fi

# (Optional) NVIDIA container toolkit setup (uncomment if needed)
# sudo dnf install -y nvidia-container-toolkit
# sudo nvidia-ctk runtime configure --runtime=docker
# sudo systemctl restart docker docker.socket containerd.service

# Prepare model directories
echo "Creating model directories..."
mkdir -p ./models/ollama/gguf ./models/a1111/ckpt
mkdir -p ./openwebui_fs/data/cache
mkdir -p ./models/ollama/models

# Download model files (uncomment and set URLs as needed)
# Example:
# URL="https://huggingface.co/MaziyarPanahi/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct.Q8_0.gguf"
# curl -L "$URL" -o ./models/ollama/gguf/"$(basename "$URL")"

# Link environment file
rm -f .env && ln -s env.desktop .env

CF="genai-docker-compose.yaml"
CFG="genai-docker-compose.nvidia-override.yaml"
COMFYUI_WORKFLOW_MODEL="v1-5-pruned-emaonly-fp16.safetensors"
sed -i -e "s@xxxCOMFYUI_WORKFLOW_MODELxxx@${COMFYUI_WORKFLOW_MODEL}@g" -e "s@xxxCOMFYUI_WORKFLOWxxx@$(echo $(cat "comfyui_fs/${COMFYUI_WORKFLOW_MODEL}.json"))@g" .env

echo "Creating Docker networks..."
docker network create genai-public-net || true
docker network create genai-private-net || true

for SERV in openwebui-dl libretranslate-dl ollama-dl vllm-dl comfyui-dl openedaispeech-dl; do
  echo "Building and running $SERV..."
  docker compose -f "$CF" build "$SERV"
  docker compose -f "$CF" run "$SERV"
done

echo "Starting all services in detached mode..."
docker compose -f "$CF" up --remove-orphans --detach

# First boot instructions (manual steps)
echo ""
echo "Open http://127.0.0.1:11080/ in your browser."
echo "Create admin user: admin, a@b.com, <somePW>"
echo "Go to 'Admin Panel' > 'Settings' > enable 'Enable New Sign Ups'"
echo "To import translate function:"
echo "Go to 'Admin Panel' > 'Functions' > 'Import Functions' -> select from libretranslate_fs -> Enable and Enable Global -> Valves -> change 'default' to http://libretranslate:5000"
echo ""
echo "To register new models in ollama, see the README.md for advanced instructions."

# Podman setup (optional, uncomment if needed)
# chcon -t container_file_t *_fs/download_models.sh
# loginctl enable-linger $(whoami)
# mkdir -p ~/.config/containers /tmp/$(whoami)/containers/storage
# cat <<EOF > ~/.config/containers/storage.conf
# [storage]
# driver="overlay"
# runroot = "/run/user/$(id -u)/containers/storage"
# graphroot = "/tmp/$(whoami)/containers/storage"
# rootless_storage_path="/tmp/$(whoami)/containers/storage"
# [storage.options]
# mount_program = "/usr/bin/fuse-overlayfs"
# [storage.options.overlay]
# mountopt="xattr_permissions=2,threaded=1"
# EOF
# docker run hello-world
