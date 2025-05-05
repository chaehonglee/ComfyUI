#!/usr/bin/env bash
# -----------------------------------------------------------------
#  setup-upscale.sh — install custom nodes and helper weights
#
#  Usage examples:
#      bash setup-upscale.sh                   # default ~/ComfyUI
#      bash setup-upscale.sh /opt/ComfyUI      # explicit path
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
    git -C "$DIR" pull
  else
    echo "Cloning $(basename "$REPO") ..."
    git clone --depth 1 "$REPO" "$DIR"
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
clone https://github.com/jags111/efficiency-nodes-comfyui

# -------- 2. Python deps -----------------------------------------------------
if [ "$PIP_OK" != "--no-pip" ]; then
  echo "Checking for requirements.txt files in custom_nodes ..."
  mapfile -t REQS < <(find "$NODE_DIR" -maxdepth 3 -type f -iname "requirements*.txt")
  if (( ${#REQS[@]} )); then
    for FILE in "${REQS[@]}"; do
      echo "Installing deps from ${FILE#"$NODE_DIR/"}"
      python -m pip install --upgrade -r "$FILE"
    done
  else
    echo "No requirements files found."
  fi

  python - <<'PY'
import importlib, subprocess, sys
missing = [m for m in ("ultralytics", "timm", "onnx") if importlib.util.find_spec(m) is None]
if missing:
    print(f"Installing fallback deps: {' '.join(missing)}")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "--upgrade", *missing])
PY
fi

# -------- 3. helper weights / checkpoints -----------------------------------
echo "Downloading helper models (HF login may be required) ..."

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

# Layermask despendencies
mkdir -p "$COMFY_DIR/models/vitmatte"
huggingface-cli download --resume-download \
  chflame163/ComfyUI_LayerStyle \
  --local-dir "$COMFY_DIR/models" \
  --local-dir-use-symlinks False

huggingface-cli download --resume-download \
  hustvl/vitmatte-small-composition-1k \
  --local-dir "$COMFY_DIR/models/vitmatte" \
  --local-dir-use-symlinks False

echo
echo "All custom nodes, their Python deps, and helper models are installed."
echo " - Restart ComfyUI (and clear your browser cache) to load the new nodes."
if [ "$PIP_OK" == "--no-pip" ]; then
  echo " - You skipped pip installs; make sure required libs are present manually."
fi
