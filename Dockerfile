FROM nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 PIP_NO_CACHE_DIR=1 PYTHONDONTWRITEBYTECODE=1 \
    COMFY_DIR=/opt/ComfyUI

# Systempakete
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-pip python3-venv git ffmpeg libgl1 libglib2.0-0 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ComfyUI + PyTorch (CUDA 12.1)
RUN git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git ${COMFY_DIR} \
 && python3 -m pip install --upgrade pip wheel setuptools \
 && python3 -m pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cu121 \
      torch torchvision torchaudio \
 && python3 -m pip install --no-cache-dir -r ${COMFY_DIR}/requirements.txt \
 && python3 -m pip install --no-cache-dir jupyterlab

EXPOSE 3000 8888

# Startskript
CMD bash -lc '\
  mkdir -p /workspace/logs; \
  [ -d /workspace/models ] && ln -sfn /workspace/models ${COMFY_DIR}/models; \
  [ -d /workspace/custom_nodes ] && ln -sfn /workspace/custom_nodes ${COMFY_DIR}/custom_nodes; \
  nohup jupyter lab --no-browser --ip=0.0.0.0 --port=8888 --ServerApp.token="" --ServerApp.password="" --allow-root \
    >> /workspace/logs/jupyter.log 2>&1 & \
  nohup python3 ${COMFY_DIR}/main.py --listen 0.0.0.0 --port 3000 --enable-cors-header "*" \
    >> /workspace/logs/comfy.log 2>&1 & \
  tail -F /workspace/logs/*.log'
