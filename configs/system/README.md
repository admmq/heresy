# Installation tips

## 1. Making swap file

```sh
dd if=/dev/zero of=/mnt/swapfile bs=1M count=8192 status=progress
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
```

## 2. Encrypt and format the disk

For example, I have two partitions: /dev/nvme0n1p1 and /dev/nvme0n1p2

Check the disk:

```sh
lsblk -f
```

This will return UUIDs.

Format the EFI partition and encrypt the second one (it's uuid is
709238c7-4c27-4ed0-b069-a1479ee154f5):

```sh
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 \
  --uuid 709238c7-4c27-4ed0-b069-a1479ee154f5 /dev/nvme0n1p2
```
```sh
cryptsetup luksUUID /dev/nvme0n1p2
```

It must print `709238c7-4c27-4ed0-b069-a1479ee154f5`.

Open the encrypted partition, create the file system inside it and mount
everything:

```sh
cryptsetup open /dev/nvme0n1p2 cryptroot
mkfs.ext4 -L ROOT /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot/efi
mount /dev/nvme0n1p1 /mnt/boot/efi
```

