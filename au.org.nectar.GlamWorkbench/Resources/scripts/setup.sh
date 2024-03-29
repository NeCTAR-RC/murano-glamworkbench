#!/bin/bash -xe

USERNAME="ubuntu"

# Assume last disk is our attached storage,
# except /dev/vda which is our root disk
DISK=$(ls /dev/vd[b-z] | tail -n1)

# Check if the disk is mounted (e.g. if ephemeral)
MOUNTPOINT=$(lsblk -n $DISK -o MOUNTPOINT)

# If we have a disk, but it's not mounted, then it's probably
# our external volume for home
if [ ! -z $DISK ] && [ -z $MOUNTPOINT ]; then

	# Have external mount for /home
	MOUNT="/homevol"

	# Partition label
	if [ "$(lsblk -n -o PARTTYPE $DISK)" == "" ]; then
		parted $DISK mklabel msdos
	fi

	# Partition
	if ! lsblk -n $DISK | grep -q " part "; then
		parted -a opt $DISK mkpart primary ext4 0% 100%
	fi

	# Filesystem
	if [ "$(lsblk -n -o FSTYPE ${DISK}1)" == "" ]; then
		mkfs.ext4 ${DISK}1
	fi

	# Mount volume
	if ! mount | grep -q $MOUNT; then
		mkdir -p $MOUNT
		echo "${DISK}1 $MOUNT ext4 defaults 0 2" >> /etc/fstab
		mount $MOUNT
	fi
else
	# Use regular /home/${USERNAME} if no volume is found
	MOUNT="/home/${USERNAME}"
fi

set +x
# Set password for user (and don't log it)
PASSWORD="$1"
echo "${USERNAME}:${PASSWORD}" | chpasswd
set -x

# Set the workbench
WORKBENCH="$2"

# Set the work folder
WORKDIR="${MOUNT}/work"
mkdir -p ${WORKDIR}
chown "${USERNAME}:${USERNAME}" ${WORKDIR}

echo "Downloading and Installing ${WORKBENCH}"
# Spin up the container
docker run -d --rm -p 8888:8888 --name "$WORKBENCH" -v "$WORKDIR:/home/jovyan/work" "registry.rc.nectar.org.au/quay.io/glamworkbench/$WORKBENCH" repo2docker-entrypoint jupyter lab --ip 0.0.0.0 --ServerApp.token="$PASSWORD" --LabApp.default_url='/lab/tree/index.ipynb'
