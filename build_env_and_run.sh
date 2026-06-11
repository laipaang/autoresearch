#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$HOME/.cache/autoresearch"
DATA_DIR="$CACHE_DIR/data"
TOKENIZER_DIR="$CACHE_DIR/tokenizer"
FLASH_ATTN_URL="http://data-im.baidu-int.com:/home/work/var/CI_DATA/im/static/flash_attn-2.8.3+cu128torch2.10-cp310-cp310-linux_x86_64.whl/flash_attn-2.8.3+cu128torch2.10-cp310-cp310-linux_x86_64.whl.1"
DATA_URL="http://data-im.baidu-int.com:/home/work/var/CI_DATA/im/static/karpathy-climbmix-400b-shuffle.tar.gz/karpathy-climbmix-400b-shuffle.tar.gz.1"
TOKENIZER_URL="http://data-im.baidu-int.com:/home/work/var/CI_DATA/im/static/tokenizer.tar.gz/tokenizer.tar.gz.1"

# 1. 初始化环境
if [ ! -d "$SCRIPT_DIR/.venv" ]; then
    pip install uv
    uv venv "$SCRIPT_DIR/.venv"
fi
source "$SCRIPT_DIR/.venv/bin/activate"
export UV_INDEX_URL=https://pip.baidu-int.com/simple

# 2. 安装依赖
uv pip install -r "$SCRIPT_DIR/requirements.txt"
FLASH_ATTN_WHL="$CACHE_DIR/flash_attn-2.8.3+cu128torch2.10-cp310-cp310-linux_x86_64.whl"
if ! python -c "import flash_attn" 2>/dev/null; then
    wget -O "$FLASH_ATTN_WHL" "$FLASH_ATTN_URL"
    uv pip install "$FLASH_ATTN_WHL"
    rm -f "$FLASH_ATTN_WHL"
fi

# 3. 下载数据（并行，已存在则跳过）
mkdir -p "$CACHE_DIR"

if [ ! -d "$DATA_DIR" ]; then
    wget -O "$CACHE_DIR/data.tar.gz" "$DATA_URL"
    mkdir -p "$DATA_DIR"
    tar -xzf "$CACHE_DIR/data.tar.gz" -C "$DATA_DIR" --strip-components=1
    rm -f "$CACHE_DIR/data.tar.gz"
fi &

if [ ! -d "$TOKENIZER_DIR" ]; then
    wget -O "$CACHE_DIR/tokenizer.tar.gz" "$TOKENIZER_URL"
    mkdir -p "$TOKENIZER_DIR"
    tar -xzf "$CACHE_DIR/tokenizer.tar.gz" -C "$TOKENIZER_DIR" --strip-components=1
    rm -f "$CACHE_DIR/tokenizer.tar.gz"
fi &

wait

# 4. 启动训练
cd "$SCRIPT_DIR"
python train.py
