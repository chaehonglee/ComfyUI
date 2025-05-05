#!/usr/bin/env bash
# -----------------------------------------------------------------
#  setup-upscale.sh — install custom nodes and helper weights
#
#  Usage examples:
#      bash setup-upscale.sh                # default ~/ComfyUI
#      bash setup-upscale.sh /opt/ComfyUI   # explicit path
#      bash setup-upscale.sh /opt/ComfyUI --no-pip   # skip pip deps
# -----------------------------------------------------------------
set -euo pipefail

# -------- 0. locations -------------------------------------------------------
COMFY_DIR="${1:-$HOME/ComfyUI}"   # first arg overrides, else ~/ComfyUI
PIP_OK="${2:-}"                   # pass --no-pip to skip python installs

if [ ! -d "$COMFY_DIR" ]; then
  echo "ERROR: ComfyUI not found at $COMFY_DIR"
  exit 1
fi

NODE_DIR="$COMFY_DIR/custom_nodes"
mkdir -p "$NODE_DIR"

# -------- helper: clone or pull ---------------------------------------------
clone () {
  local REPO="$1"
  local DIR="$NODE_DIR/$(basename "$REPO")"
  if [ -d "$DIR/.git" ]; then
    echo "Updating $(basename "$REPO") ..."
    git -C "$DIR" pull --quiet
  else
    echo "Cloning $(basename "$REPO") ..."
    git clone --quiet --depth 1 "$REPO" "$DIR"
  fi
}

# -------- 1. custom node packs ----------------------------------------------
clone https://github.com/chflame163/ComfyUI_LayerStyle_Advance
clone https://github.com/kijai/ComfyUI-KJNodes
clone https://github.com/rgthree/rgthree-comfy
clone https://github.com/ltdrdata/ComfyUI-Impact-Pack
clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack
clone https://github.com/WASasquatch/was-node-suite-comfyui
clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale
clone https://github.com/chrisgoringe/cg-use-everywhere
clone https://github.com/bash-j/mikey_nodes
clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts
clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes

# -------- 2. runtime python deps for Impact-Pack (Ultralytics & SAM) ---------
if [ "$PIP_OK" != "--no-pip" ]; then
  echo "Installing Ultralytics + timm (sudo may prompt)..."
  python -m pip install --quiet --upgrade ultralytics timm onnx
fi

# -------- 3. helper weights / checkpoints -----------------------------------
echo "Downloading helper models (HF login may be required)..."

mkdir -p \
  "$COMFY_DIR/models/ultralytics/bbox" \
  "$COMFY_DIR/models/sam" \
  "$COMFY_DIR/models/upscale_models" \
  "$COMFY_DIR/models/loras"

# YOLO v8 face detector
huggingface-cli download --resume-download Bingsu/adetailer \
  face_yolov8m.pt \
  --local-dir "$COMFY_DIR/models/ultralytics/bbox" \
  --local-dir-use-symlinks False

# SAM-B weights
huggingface-cli download --resume-download Gourieff/ReActor \
  sam_vit_b_01ec64.pth \
  --local-dir "$COMFY_DIR/models/sam" \
  --local-dir-use-symlinks False

# ESRGAN 4x upscaler
huggingface-cli download --resume-download ffxvs/upscaler \
  ESRGAN_4x.pth \
  --local-dir "$COMFY_DIR/models/upscale_models" \
  --local-dir-use-symlinks False

# Flux Realism LoRA
huggingface-cli download --resume-download \
  comfyanonymous/flux_RealismLora_converted_comfyui \
  flux_realism_lora.safetensors \
  --local-dir "$COMFY_DIR/models/loras" \
  --local-dir-use-symlinks False

echo
echo "SUCCESS: Custom nodes and upscale assets installed."
echo " - Restart ComfyUI (and clear browser cache) to load new nodes."
if [ "$PIP_OK" = "--no-pip" ]; then
  echo " - Remember to ensure Ultralytics + timm are available in your venv."
fi
