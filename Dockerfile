FROM runpod/stable-diffusion:comfy-ui-6.0.0
ARG COMFY_SHA
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 PIP_NO_CACHE_DIR=1 PYTHONDONTWRITEBYTECODE=1 COMFY_DIR=/opt/ComfyUI
RUN rm -rf ${COMFY_DIR} && \
    git clone https://github.com/comfyanonymous/ComfyUI.git ${COMFY_DIR} && \
    git -C ${COMFY_DIR} checkout ${COMFY_SHA} && \
    python -m pip install -U pip wheel setuptools && \
    python -m pip install -r ${COMFY_DIR}/requirements.txt && \
    python -m pip install jupyterlab
CMD bash -lc '\
  mkdir -p /workspace/logs /workspace/models /workspace/custom_nodes; \
  ln -sfn /workspace/models ${COMFY_DIR}/models; \
  ln -sfn /workspace/custom_nodes ${COMFY_DIR}/custom_nodes; \
  echo "COMFY_COMMIT: $(git -C ${COMFY_DIR} rev-parse --short HEAD)" >> /workspace/logs/comfy.log 2>&1; \
  nohup jupyter lab --no-browser --ip=0.0.0.0 --port=8888 \
    --ServerApp.token="${JUPYTER_TOKEN:-}" --ServerApp.password="" --allow-root >> /workspace/logs/jupyter.log 2>&1 & \
  nohup python ${COMFY_DIR}/main.py --listen 0.0.0.0 --port 3000 --enable-cors-header "*" >> /workspace/logs/comfy.log 2>&1 & \
  tail -F /workspace/logs/*.log'
