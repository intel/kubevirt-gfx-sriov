#!/bin/bash

trap 'rm -rf "$buildir"' EXIT

# helper functions
info()
{
  echo '[INFO] ' "$@"
}
warn()
{
  echo '[WARN] ' "$@" >&2
}
fatal()
{
  echo '[ERROR] ' "$@" >&2
  exit 1
}

create_dockerfile()
{
cat <<EOF > Dockerfile
FROM scratch
ADD --chown=107:107 $1 /disk/
EOF
}

create_cdisk_from_folder()
{
  info 'building container disk from folder'
 
  local folder_path=$1
  local name_tag=$2
  local push_img=$3
  local archive_filename="archive.zip"
  local iso_filename="archive.iso"

  buildir=$(mktemp -d)
  pushd $buildir

  zip -r $archive_filename $folder_path
  if [[ ! -f $archive_filename ]]; then
    fatal "Fail to create file: $archive_filename"
  fi

  mkisofs -r -J -o $iso_filename $archive_filename
  if [[ ! -f $iso_filename ]]; then
    fatal "Fail to create file: $iso_filename"
  fi
 
  create_dockerfile $iso_filename
  if [[ ! -f "Dockerfile" ]]; then
    fatal "Fail to create file: Dockerfile"
  fi

  # build container disk
  docker build -t $name_tag .
  if [[ $push_img == true ]]; then
    docker push $name_tag
  fi

  popd
  rm -rf $buildir
}

create_cdisk_from_iso()
{
  info 'building container disk from ISO file'

  local iso_filepath=$1
  local name_tag=$2
  local iso_filename="cdrom.iso"

  buildir=$(mktemp -d)
  pushd $buildir

  cp $iso_filepath .
  mv $(basename -- $iso_filepath) $iso_filename

  create_dockerfile $iso_filename
  if [[ ! -f "Dockerfile" ]]; then
    fatal "Fail to create file: Dockerfile"
  fi

  # build container disk
  docker build -t $name_tag .
  if [[ $push_img == true ]]; then
    docker push $name_tag
  fi

  popd
  rm -rf $buildir
}

create_cdisk_from_diskimage()
{
  info 'building container disk from disk image'

  local img_filepath=$1
  local name_tag=$2
  local img_filename="disk.img"

  buildir=$(mktemp -d)
  pushd $buildir

  cp $img_filepath .
  mv $(basename -- $img_filepath) $img_filename

  create_dockerfile $img_filename
  if [[ ! -f "Dockerfile" ]]; then
    fatal "Fail to create file: Dockerfile"
  fi

  # build container disk
  docker build -t $name_tag .
  if [[ $push_img == true ]]; then
    docker push $name_tag
  fi

  popd
  rm -rf $buildir
}

command_exists()
{
  command -v "$@" > /dev/null 2>&1
}

usage() 
{
  echo ""
  echo "Usage: $0 [option] <path> -t <name:tag>"
  echo ""
  echo "For each operation, only one of the following option: [-d, -i or -f] may be specified" 
  echo "Note: -t <name:tag> option is mandatory."
  echo ""
  echo "option:"
  echo "    -d <path> : folder specified in 'path' to be included in container disk." 
  echo "                The folder will be zip and converted to iso file before build"
  echo "    -i <path> : iso file to be included in container disk" 
  echo "    -f <path> : qcow2 or img file to be included in container disk"
  echo "    -p        : push built image to registry"
  echo "    -h        : help"
  echo ""
  echo "Example:"
  echo "  # Build container disk from folder and iso file"
  echo "      $0 -d ../myfolder/ -t docker.io/myrepo/myimage:latest"
  echo "      $0 -i file.iso -t quay.io/myrepo/myimage:2.0.1"
  echo "  # Build container disk from disk image file and push image to registery "
  echo "      $0 -f image.img -p -t docker.io/myrepo/myimage:v1.0" 
  echo "      $0 -f image.qcow2 -p -t quay.io/myrepo/myimage:0.5"
  echo ""
}

clear
[ $# -eq 0 ] && usage && exit 0

OPT_COUNT=0
while getopts "d:i:f:t:hp" opt; do
  case "$opt" in
    d)
      ((OPT_COUNT++))
      OPT_FOLDER=true
      FOLDER_PATH=$OPTARG      
      ;;
    i)
      ((OPT_COUNT++))
      OPT_ISO=true
      ISO_PATH=$OPTARG
      ;;
    f)
      ((OPT_COUNT++))
      OPT_DISKIMG=true
      DISKIMG_PATH=$OPTARG
      ;;
    t)
      NAME_TAG=$OPTARG
      ;;
    p)
      PUSH_IMG=true
      ;;
    h | *)
      usage
      exit 0
      ;;
  esac
done

# check for invalid input
if [[ $OPT_COUNT -eq 0 ]]; then
  echo "$0: no [-i, -d or -f] option being specified"
  usage
  exit 1
fi

if [[ $OPT_COUNT -gt 1 ]]; then
  echo "$0: not more than one of these options [-i, -d or -f] may be specified"
  usage
  exit 1
fi

if [[ -z $NAME_TAG ]]; then
  echo "$0: 'name:tag' not specified"
  usage
  exit 1
fi

# check is docker installed
if ! command_exists docker; then
  fatal 'The "docker" command does not exist on this system'
fi

# option: OPT_FOLDER
if [[ $OPT_FOLDER = true && ! -z $FOLDER_PATH ]]; then
  if [[ ! -d $FOLDER_PATH ]]; then
    fatal "Fail to find folder: \"$FOLDER_PATH\""
  fi
  create_cdisk_from_folder $FOLDER_PATH $NAME_TAG $PUSH_IMG
fi

# option: OPT_ISO
if [[ $OPT_ISO = true && ! -z $ISO_PATH ]]; then
  if [[ ! -f $ISO_PATH ]]; then
    fatal "Fail to find file: \"$ISO_PATH\""
  fi

  if [[ $ISO_PATH != *iso ]]; then
    fatal "Incorrect ISO file extension: \"$ISO_PATH\""
  fi
  create_cdisk_from_iso $ISO_PATH $NAME_TAG $PUSH_IMG 
fi

# option: OPT_DISKIMG
if [[ $OPT_DISKIMG = true && ! -z $DISKIMG_PATH ]]; then
  if [[ ! -f $DISKIMG_PATH ]]; then
    fatal "Fail to find file: \"$DISKIMG_PATH\""
  fi

  if [[ $DISKIMG_PATH != *img && $DISKIMG_PATH != *qcow2 ]]; then
    fatal "Incorrect disk image file extension: \"$DISKIMG_PATH\""
  fi
  create_cdisk_from_diskimage $DISKIMG_PATH $NAME_TAG $PUSH_IMG
fi