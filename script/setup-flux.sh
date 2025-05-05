#!/usr/bin/env bash
# flux-dev-full-install.sh
# -----------------------------------------------------------
# Downloads all core weights for the Flux‑Dev workflow:
#   - flux1-dev.safetensors  -> models/diffusion_models/
#   - ae.safetensors         -> models/vae/
#   - t5xxl_fp16.safetensors -> models/text_encoders/
#   - clip_l.safetensors     -> models/text_encoders/
#
# Usage: bash flux-dev-full-install.sh [/path/to/ComfyUI]
# -----------------------------------------------------------
set -euo pipefail

# 1. Where is ComfyUI?
COMFY_DIR="${1:-$HOME/ComfyUI}"   # optional first arg overrides default
if [ ! -d "$COMFY_DIR" ]; then
  echo "ERROR: ComfyUI not found at $COMFY_DIR"
  exit 1
fi

# 2. Ensure destination subdirectories exist
mkdir -p \
  "$COMFY_DIR/models/diffusion_models" \
  "$COMFY_DIR/models/vae" \
  "$COMFY_DIR/models/text_encoders"

# 3. Check that the Hugging Face CLI is available
if ! command -v huggingface-cli >/dev/null; then
  echo "ERROR: huggingface-cli not on PATH (pip install 'huggingface_hub[cli]')"
  exit 1
fi

echo "Downloading Flux‑Dev UNet (~23 GB)..."
huggingface-cli download --resume-download black-forest-labs/FLUX.1-dev \
  flux1-dev.safetensors \
  --local-dir "$COMFY_DIR/models/diffusion_models" \
  --local-dir-use-symlinks False

echo "Downloading VAE (~335 MB)..."
huggingface-cli download --resume-download black-forest-labs/FLUX.1-dev \
  ae.safetensors \
  --local-dir "$COMFY_DIR/models/vae" \
  --local-dir-use-symlinks False

echo "Downloading T5‑XXL text encoder/decoder (~9.8 GB)..."
huggingface-cli download --resume-download comfyanonymous/flux_text_encoders \
  t5xxl_fp16.safetensors \
  --local-dir "$COMFY_DIR/models/text_encoders" \
  --local-dir-use-symlinks False

echo "Downloading CLIP‑L text encoder (~246 MB)..."
huggingface-cli download --resume-download comfyanonymous/flux_text_encoders \
  clip_l.safetensors \
  --local-dir "$COMFY_DIR/models/text_encoders" \
  --local-dir-use-symlinks False

echo "All Flux‑Dev weights are in place. Launch ComfyUI and load your workflow!"
