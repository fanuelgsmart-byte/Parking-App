#!/usr/bin/env bash
# Install local AI libraries and backend dependencies
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing AI libraries from alpr_libs/..."
pip install -e "$SCRIPT_DIR/alpr_libs/fast-plate-ocr/fast-plate-ocr-master[onnx]"
pip install -e "$SCRIPT_DIR/alpr_libs/open-image-models/open-image-models-main[onnx]"
pip install -e "$SCRIPT_DIR/alpr_libs/fast-alpr/fast-alpr-master[onnx]"

echo "Installing backend dependencies..."
pip install -r "$SCRIPT_DIR/requirements.txt"

echo "Setup complete."
