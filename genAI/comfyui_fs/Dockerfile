FROM python:3.12-slim

WORKDIR /app/comfyui

ARG COMFYUI_ARCH
ARG COMFYUI_VERS

ADD https://github.com/comfyanonymous/ComfyUI/archive/refs/tags/${COMFYUI_VERS}.tar.gz /app/comfyui
RUN tar xzf *.tar.gz -C . --strip-components 1 && rm *.tar.gz

#from https://pytorch.org/get-started/locally/
RUN apt-get update -y \
	&& apt-get install -y cargo \
	&& pip3 install torch torchvision torchaudio \
		--index-url https://download.pytorch.org/whl/${COMFYUI_ARCH} \
	&& pip3 install -r requirements.txt

COPY <<EOF /app/comfyui/entrypoint.sh
readonly lsep='SPACKBELL'
IFS="\${lsep}"
IFS=' ' read -a FLAGS <<< "\${COMMANDLINE_ARGS}"
python3 main.py --listen --extra-model-paths-config emp.yaml "\${FLAGS[@]}"
EOF

ENTRYPOINT ["/bin/bash", "/app/comfyui/entrypoint.sh"]
