#!/usr/bin/env bash
# --- Nomad Dynamic Host Volume Plugin (ext4) ---
# Actions: create <VOLUME_ID> <SIZE_GB> | remount <VOLUME_ID> | delete <VOLUME_ID> | path <VOLUME_ID>
set -euo pipefail

BASE="/opt/nomad/volumes/dynamic"
REG="$BASE/.registry"
UNIT="nomad-dynvol@"

log() { echo "[ext4-volume] $*" >&2; }

ensure_dirs() {
  mkdir -p "$BASE" "$REG"
}

img_of()   { echo "$BASE/$1.img"; }
mnt_of()   { echo "$BASE/$1"; }
meta_of()  { echo "$REG/$1.env"; }

write_meta() {
  local id="$1"; local img; img="$(img_of "$id")"; local mnt; mnt="$(mnt_of "$id")"
  printf 'ID=%s\nIMG=%s\nMNT=%s\n' "$id" "$img" "$mnt" >"$(meta_of "$id")"
}

create() {
  local id="${1:?id}"; local size_gb="${2:?size_gb}"
  ensure_dirs
  local img; img="$(img_of "$id")"
  local mnt; mnt="$(mnt_of "$id")"

  [[ -e "$img" || -d "$mnt" ]] && { log "volume $id already exists"; echo "$mnt"; exit 0; }

  truncate -s "${size_gb}G" "$img"
  mkfs.ext4 -F "$img" >/dev/null
  mkdir -p "$mnt"
  mount -o loop,noatime,nodiratime "$img" "$mnt"
  write_meta "$id"

  # Enable boot remount
  systemctl enable --now "${UNIT}${id}.service" >/dev/null 2>&1 || true

  echo "$mnt"
}

remount() {
  local id="${1:?id}"
  local img; img="$(img_of "$id")"
  local mnt; mnt="$(mnt_of "$id")"
  [[ -f "$img" ]] || { log "missing image: $img"; exit 1; }
  mkdir -p "$mnt"
  mountpoint -q "$mnt" || mount -o loop,noatime,nodiratime "$img" "$mnt"
  echo "$mnt"
}

delete() {
  local id="${1:?id}"
  local img; img="$(img_of "$id")"
  local mnt; mnt="$(mnt_of "$id")"
  local meta; meta="$(meta_of "$id")"

  # Stop boot remount
  systemctl disable --now "${UNIT}${id}.service" >/dev/null 2>&1 || true

  if mountpoint -q "$mnt"; then umount "$mnt"; fi
  rm -rf "$mnt" "$img" "$meta"
}

path() {
  local id="${1:?id}"; echo "$(mnt_of "$id")"
}

case "${1:-}" in
  create)  shift; create  "$@";;
  remount) shift; remount "$@";;
  delete)  shift; delete  "$@";;
  path)    shift; path    "$@";;
  *) echo "usage: $0 {create <id> <size_gb>|remount <id>|delete <id>|path <id>}"; exit 1;;
esac
