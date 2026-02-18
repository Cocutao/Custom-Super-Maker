#!/bin/bash
# -------------------------------------------------------------------------
# AUTO-DEBLOAT & REPACK SCRIPT (by Minhmc2077) (GPL3)
# Support: Raw Input, Zip, Tar
# Kernel Target: 4.19 or newer (EROFS LZ4HC)
# Features:
#   1. Aggressive Product Debloat (Removes app/priv-app)
#   2. Maximize System Partition (Uses all remaining space)
#   3. EROFS Repack with LZ4HC (High Compression)
#   4. Detailed Compare: Stock vs Input vs EROFS
# -------------------------------------------------------------------------

script_dir=$(dirname $(readlink -f "$0"))
lptools_path="$script_dir/lpunpack_and_lpmake"

# Requirements
system_required="simg2img tar unxz lz4 unzip gzip jq file mkfs.erofs rsync"

# --- COLOR DEFINITIONS ---
if [ ! $NO_COLOR ] && [ "$TERM" != "dumb" ]; then
  RED=$(printf '\033[1;31m')
  GREEN=$(printf '\033[1;32m')
  CYAN=$(printf '\033[1;36m')
  YELLOW=$(printf '\033[1;33m')
  NC=$(printf '\033[0m')
else
  RED=""
  GREEN=""
  CYAN=""
  YELLOW=""
  NC=""
fi

# Helper: Convert Bytes to Human Readable
bytes_to_human() {
    local b=${1:-0}; local d=''; local s=0; local S=(Bytes KB MB GB TB)
    while ((b > 1024)); do
        d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        let s++
    done
    echo "$b$d ${S[$s]}"
}

# Trap for cleanup
trap_func() {
  echo -e "${RED}\n[!] Action aborted. Cleaning up mounts...${NC}"
  sudo umount "$work_dir/mnt_system" 2>/dev/null
  sudo umount "$work_dir/mnt_product" 2>/dev/null
  exit 1
}
trap trap_func INT

mkdircr() {
  mkdir -p "$1"
  if [ ! $? -eq 0 ]; then
    echo "Cannot create directory $1. Exiting..."
    exit 1
  fi
}

# Check Tools
for i in $system_required; do
  if [ ! $(which "$i") ]; then
    echo "Error: \"$i\" not found. Install it (apt install $i or erofs-utils)."
    exit 1
  fi
done

# Usage
src_input="$1"
custom_system_img="$2"
output_name="$3"

if [ -z "$src_input" ] || [ -z "$custom_system_img" ]; then
    echo "Usage: sudo $0 <super.raw OR firmware.zip> <custom_system.img> [output_name]"
    exit 1
fi
if [ -z "$output_name" ]; then output_name="super_new.img"; fi

# Directories
rps_dir="$script_dir/repacksuper"
super_dir="$rps_dir/super"
work_dir="$rps_dir/work"
stock_super_raw="$rps_dir/super.raw"

# --- CAPTURE INPUT SIZE IMMEDIATELY ---
if [ -f "$custom_system_img" ]; then
    input_source_size=$(stat --format="%s" "$custom_system_img")
else
    echo "Error: Custom system image '$custom_system_img' not found."
    exit 1
fi

# Cleanup previous run
rm -rf "$rps_dir"
mkdircr "$rps_dir"
mkdircr "$super_dir"
mkdircr "$work_dir"

# =========================================================
# 1. INPUT PROCESSING & STOCK ANALYSIS
# =========================================================
echo
printf "${CYAN}>>> Processing Input Source...${NC}\n"

# 1a. Extract/Prepare Raw
if [[ "$src_input" == *.raw ]]; then
    echo "Detected RAW image input."
    cp "$src_input" "$stock_super_raw"
elif [[ "$src_input" == *.zip ]]; then
    echo "Detected ZIP input. Extracting..."
    unzip -o "$src_input" "AP_*.tar.md5" -d "$rps_dir"
    tar_file=$(find "$rps_dir" -name "AP_*.tar.md5" | head -n1)
    tar -xf "$tar_file" -C "$rps_dir" super.img.lz4
    lz4 -d "$rps_dir/super.img.lz4" "$rps_dir/super.img"
    simg2img "$rps_dir/super.img" "$stock_super_raw"
elif [[ "$src_input" == *.tar.md5 || "$src_input" == *.tar ]]; then
    echo "Detected TAR input. Extracting..."
    tar -xf "$src_input" -C "$rps_dir" super.img.lz4
    lz4 -d "$rps_dir/super.img.lz4" "$rps_dir/super.img"
    simg2img "$rps_dir/super.img" "$stock_super_raw"
elif [[ "$src_input" == *.img ]]; then
     echo "Detected IMG input. Checking if sparse..."
     if file -b -L "$src_input" | grep "sparse image" > /dev/null; then
        simg2img "$src_input" "$stock_super_raw"
     else
        cp "$src_input" "$stock_super_raw"
     fi
else
    echo "Unknown input format. Please use .raw, .img, .tar, or .zip"
    exit 1
fi

# 1b. Analyze Stock Sizes
stock_json=$("$lptools_path"/lpdump "$stock_super_raw" -j)
stock_system_size=$(echo "$stock_json" | jq -r '.partitions[] | select(.name == "system") | .size')
stock_product_size=$(echo "$stock_json" | jq -r '.partitions[] | select(.name == "product") | .size')
if [ -z "$stock_product_size" ] || [ "$stock_product_size" == "null" ]; then stock_product_size=0; fi

# 1c. Unpack
echo "Unpacking super partitions..."
"$lptools_path"/lpunpack "$stock_super_raw" "$super_dir"

# =========================================================
# 2. DEBLOAT PRODUCT
# =========================================================
echo
printf "${CYAN}>>> [LITE MODE] Debloating Product Partition...${NC}\n"
product_img="$super_dir/product.img"
mkdircr "$work_dir/mnt_product"

if [ -f "$product_img" ]; then
    if file -b -L "$product_img" | grep "sparse image" > /dev/null; then
        simg2img "$product_img" "$product_img.raw"
        mv "$product_img.raw" "$product_img"
    fi
    sudo mount -o ro,loop "$product_img" "$work_dir/mnt_product"

    mkdircr "$work_dir/product_build"
    # DEBLOAT
    sudo rsync -aAXv "$work_dir/mnt_product/" "$work_dir/product_build/" \
        --exclude "app" --exclude "priv-app" --exclude "lost+found" > /dev/null

    sudo umount "$work_dir/mnt_product"

    echo "Repacking Product (EROFS LZ4HC)..."
    mkfs.erofs -z lz4hc,9 -T 0 --mount-point /product \
        --fs-config-file "$script_dir/config/product_fs_config" \
        "$super_dir/product_new.img" "$work_dir/product_build" 2>/dev/null || \
    mkfs.erofs -z lz4hc,9 -T 0 --mount-point /product "$super_dir/product_new.img" "$work_dir/product_build"

    mv "$super_dir/product_new.img" "$super_dir/product.img"
fi

# =========================================================
# 3. PROCESS CUSTOM SYSTEM
# =========================================================
echo
printf "${CYAN}>>> Processing Custom System Image...${NC}\n"
mkdircr "$work_dir/mnt_system"
mkdircr "$work_dir/system_build"

# Convert sparse if needed
if file -b -L "$custom_system_img" | grep "sparse image" > /dev/null; then
    simg2img "$custom_system_img" "$work_dir/system_raw.img"
    sys_mount_src="$work_dir/system_raw.img"
else
    sys_mount_src="$custom_system_img"
fi

echo "Mounting System..."
sudo mount -o ro,loop "$sys_mount_src" "$work_dir/mnt_system"

echo "Syncing System files..."
sudo rsync -aAXv "$work_dir/mnt_system/" "$work_dir/system_build/" > /dev/null
sudo umount "$work_dir/mnt_system"

echo "Repacking System (EROFS LZ4HC - Max Compression)..."
mkfs.erofs -z lz4hc,9 -T 0 --mount-point /system "$super_dir/system_new.img" "$work_dir/system_build"
mv "$super_dir/system_new.img" "$super_dir/system.img"

# =========================================================
# 4. CALCULATE & COMPARE
# =========================================================
echo
printf "${CYAN}>>> Calculating Sizes...${NC}\n"

# Get Metadata
lpdump_json=$("$lptools_path"/lpdump "$stock_super_raw" -j)
group_name=$(echo "$lpdump_json" | jq -r '.groups[] | select(.name != "default") | .name' | head -n1)
group_max_size=$(echo "$lpdump_json" | jq -r ".groups[] | select(.name == \"$group_name\") | .maximum_size")
block_device_size=$(echo "$lpdump_json" | jq -r '.block_devices[0].size')

# New Sizes
new_vendor_size=$(stat --format="%s" "$super_dir/vendor.img")
new_product_size=$(stat --format="%s" "$super_dir/product.img")
new_system_erofs_size=$(stat --format="%s" "$super_dir/system.img")
odm_size=0; [ -f "$super_dir/odm.img" ] && odm_size=$(stat --format="%s" "$super_dir/odm.img")
sys_ext_size=0; [ -f "$super_dir/system_ext.img" ] && sys_ext_size=$(stat --format="%s" "$super_dir/system_ext.img")

# Calculate Limits
used_space=$((new_vendor_size + new_product_size + odm_size + sys_ext_size))
available_space=$((group_max_size - used_space))
buffer=4194304
new_system_part_size=$((available_space - buffer))

if [ $new_system_erofs_size -gt $new_system_part_size ]; then
    echo -e "${RED}ERROR: EROFS Image ($(bytes_to_human $new_system_erofs_size)) exceeds Available Space ($(bytes_to_human $new_system_part_size))!${NC}"
    exit 1
fi

# --- COMPARISON TABLE ---
echo -e "${YELLOW}=========================================================================================${NC}"
echo -e "${YELLOW}                                PARTITION SIZE COMPARISON                                ${NC}"
echo -e "${YELLOW}=========================================================================================${NC}"
printf "%-10s | %-15s | %-15s | %-15s | %-15s\n" \
    "PARTITION" "STOCK LIMIT" "INPUT SOURCE" "EROFS RESULT" "NEW LIMIT"
echo "-----------------------------------------------------------------------------------------"

# Product Row
printf "%-10s | %-15s | %-15s | %-15s | %-15s\n" \
    "PRODUCT" \
    "$(bytes_to_human $stock_product_size)" \
    "N/A" \
    "$(bytes_to_human $new_product_size)" \
    "$(bytes_to_human $new_product_size)"

echo "-----------------------------------------------------------------------------------------"

# System Row
erofs_saved=$((input_source_size - new_system_erofs_size))

printf "%-10s | %-15s | %-15s | %-15s | %-15s\n" \
    "SYSTEM" \
    "$(bytes_to_human $stock_system_size)" \
    "$(bytes_to_human $input_source_size)" \
    "${GREEN}$(bytes_to_human $new_system_erofs_size)${NC}" \
    "$(bytes_to_human $new_system_part_size)"

echo "-----------------------------------------------------------------------------------------"
echo "EROFS Compression Effect: Reduced System from $(bytes_to_human $input_source_size) -> $(bytes_to_human $new_system_erofs_size)"
echo "Space Saved by Compression: $(bytes_to_human $erofs_saved)"
echo -e "${YELLOW}=========================================================================================${NC}"
echo

# =========================================================
# 5. REPACK SUPER
# =========================================================
printf "${CYAN}>>> Building Super Image...${NC}\n"

args="--metadata-size 65536 --super-name super --metadata-slots 2"
args="$args --device super:$block_device_size"
args="$args --group $group_name:$group_max_size"

args="$args --partition system:readonly:$new_system_part_size:$group_name --image system=$super_dir/system.img"
args="$args --partition vendor:readonly:$new_vendor_size:$group_name --image vendor=$super_dir/vendor.img"
args="$args --partition product:readonly:$new_product_size:$group_name --image product=$super_dir/product.img"

if [ $odm_size -gt 0 ]; then
    args="$args --partition odm:readonly:$odm_size:$group_name --image odm=$super_dir/odm.img"
fi
if [ $sys_ext_size -gt 0 ]; then
    args="$args --partition system_ext:readonly:$sys_ext_size:$group_name --image system_ext=$super_dir/system_ext.img"
fi

args="$args --sparse --output $output_name"

"$lptools_path"/lpmake $args

if [ $? -eq 0 ]; then
    echo -e "${GREEN}SUCCESS: $output_name created successfully.${NC}"
else
    echo -e "${RED}FAILED: lpmake returned an error.${NC}"
    exit 1
fi
