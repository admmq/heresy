# Reinstalling Guix on the laptop with an encrypted disk

This erases everything on the laptop's disk and installs
[`laptop.scm`](laptop.scm) with full-disk encryption.

What you end up with:

- `nvme0n1p1`, 600 MB: the EFI partition, unencrypted, label `BOOT`.
- `nvme0n1p2`, the rest: encrypted with LUKS2. Inside is one ext4 file
  system labelled `ROOT` with the whole system, `/home`, and the 8 GiB swap
  file, so swap is encrypted too.
- One passphrase at power-on, typed into GRUB. GRUB passes the key on to the
  system, so you aren't asked a second time.

The install has two stages:

1. From the installer, install [`laptop-install.scm`](laptop-install.scm):
   the same system, but with nonguix's stock kernel and without the Amnezia
   VPN service. Both of those would have to be compiled inside the installer,
   which runs from RAM. The stock kernel can be downloaded ready-made.
2. On the installed system, switch to the full `laptop.scm`. This compiles
   your own kernel and Amnezia VPN, and takes hours.

## 1. Before you start, on the laptop as it is now

1. **Back up** everything you need from `/home/user` to another disk or
   computer: documents, `~/.ssh`, `~/.gnupg`, browser profiles, password
   stores, your Amnezia VPN keys, and anything else that isn't in git.

2. **Push the repo.** The installer clones it from GitHub.

   ```sh
   cd ~/Documents/Code/heresy
   git status    # must show nothing left to commit
   git push
   ```

   The commands below use the branch `channel-add-waymacs`. If you merge it
   into `main` first, use `main` instead.

3. **Pre-flight check** that the first-stage config works with your current
   Guix. It only computes what would be built, but that takes a lot of
   memory, so close heavy programs. If `swapon --show` prints nothing, add a
   temporary swap file first:

   ```sh
   sudo dd if=/dev/zero of=/swapfile bs=1M count=8192 status=progress
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

   Then:

   ```sh
   guix system build --dry-run -L channel configs/system/laptop-install.scm
   ```

   It should end with lists of things that would be built or downloaded,
   not with an error.

4. **Build the installer image.** This is nonguix's version of the Guix
   installer: nonfree kernel and firmware, so the Wi-Fi works. It also
   already trusts nonguix's substitute server and includes `git`. First let
   your current system download from nonguix, so the image's kernel is
   downloaded instead of compiled:

   ```sh
   curl -sS https://substitutes.nonguix.org/signing-key.pub | sudo guix archive --authorize
   guix system image --image-type=iso9660 --cores=2 \
     ~/.config/guix/current/share/guile/site/3.0/nongnu/system/install.scm
   ```

   It takes a while and prints the image's path at the end, a
   `/gnu/store/...-image.iso` file.

5. **Write the image to a USB stick.** This erases the stick. Find the stick
   with `lsblk`: it's usually `/dev/sdb` or similar, never `nvme0n1`.

   ```sh
   lsblk
   sudo dd if=/gnu/store/...-image.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```

6. **Choose the disk passphrase.** Use only Latin letters, digits and common
   symbols. GRUB reads it with a US keyboard layout, so Cyrillic letters or
   another layout won't work.

## 2. Boot the installer

1. Plug in the stick, power on, and pick the stick in the firmware's boot
   menu. The key depends on the laptop; F12, F8 or Esc are common. Secure Boot
   must stay off; it already is, since Guix boots on this laptop now.

2. When the installer's menu appears, press **Ctrl+Alt+F3**, then **Enter**.
   You get a root shell. Everything below happens there.

3. **Connect to Wi-Fi.** If Wi-Fi turns out to be blocked, run
   `rfkill unblock all` first.

   ```sh
   connmanctl
   ```

   Then, at the `connmanctl>` prompt:

   ```
   enable wifi
   scan wifi
   services
   agent on
   connect wifi_..._psk
   quit
   ```

   `services` lists the networks. The long `wifi_..._psk` name next to yours
   is what `connect` takes; Tab completes it. It then asks for the Wi-Fi
   password. Check that it works:

   ```sh
   ping -c 3 gnu.org
   ```

4. **Optional:** to copy and paste the commands from another computer instead
   of typing them, start SSH in the installer:

   ```sh
   passwd                  # a temporary root password, only for the installer
   herd start ssh-daemon
   ip -4 addr              # note the laptop's address, e.g. 192.168.1.23
   ```

   Then on the other computer: `ssh root@192.168.1.23`.

## 3. Encrypt and format the disk

Check the disk:

```sh
lsblk -o NAME,SIZE,FSTYPE,LABEL
```

You should see `nvme0n1p1` (600M, vfat, `BOOT`) and `nvme0n1p2` (the rest).
The commands below reuse these two partitions. If the layout looks different,
stop and work out the right partitions first.

Format the EFI partition and encrypt the big one:

```sh
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 \
  --uuid 709238c7-4c27-4ed0-b069-a1479ee154f5 /dev/nvme0n1p2
```

Type `YES` in capitals, then the passphrase twice.

- `--pbkdf pbkdf2`: GRUB has to unlock this partition to read `/gnu/store`,
  and PBKDF2 is the key-derivation method GRUB unlocks reliably.
- `--uuid ...`: `laptop.scm` finds the partition by this UUID, so it must
  match exactly. Check it:

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

## 4. Swap, and keeping the installer's data on disk

Create the 8 GiB swap file and turn it on now. The installer runs from RAM,
so this gives it room:

```sh
dd if=/dev/zero of=/mnt/swapfile bs=1M count=8192 status=progress
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
```

Make the installer keep downloads and builds on the disk instead of in RAM:

```sh
herd start cow-store /mnt
```

## 5. Install the first stage

Get the repo:

```sh
git clone --branch channel-add-waymacs https://github.com/admmq/heresy
cd heresy
```

Install:

```sh
guix system init --cores=2 -L channel configs/system/laptop-install.scm /mnt
```

First it asks for the new passwords of `root` and of your account `user`,
each twice. Nothing is shown while you type. The installer uses a US keyboard
layout, the same as the login screen will.

Then it lists what it will build and what it will download. The build list
should be short: your Emacs configuration, the initrd and small system files.
If a kernel (a `linux-` package) is in it, nonguix has no ready-made build of
it yet. The install still works, but takes hours longer.

This is mostly downloading. If it stops with an error, read the message and
run the same command again. It asks for the passwords again and continues
where it left off.

When it finishes without an error, reboot and remove the USB stick:

```sh
reboot
```

## 6. First boot

1. GRUB asks for the passphrase. After you type it, nothing seems to happen
   for 10–30 seconds; GRUB's unlocking is slow. You shouldn't be asked again.
   If you are, type it again; the system still boots normally.

2. At the login screen, log in as `user` with the password you chose during
   the install, and connect to Wi-Fi.

## 7. Second stage: the full `laptop.scm`

In a terminal:

```sh
mkdir -p ~/Documents/Code
cd ~/Documents/Code
guix shell git -- git clone --branch channel-add-waymacs https://github.com/admmq/heresy
cd heresy
```

Pull your channels, so that `guix` includes nonguix and your channel. This
takes a while:

```sh
guix pull -C configs/bootstrap.scm --unsafe-channel-evaluation
hash guix
```

Switch to the full system. This compiles your kernel and Amnezia VPN, which
takes hours, so keep the laptop plugged in:

```sh
sudo guix system reconfigure --cores=2 -L channel configs/system/laptop.scm
```

Reboot when it's done. Then set up your home environment and copy your
backups back:

```sh
guix home reconfigure -L channel configs/home/home-configuration.scm
```

## If something goes wrong

- **GRUB shows `grub rescue>` or never asks for the passphrase.** The
  partition probably has a different UUID, or wasn't formatted with
  `--pbkdf pbkdf2`. Boot the installer and compare
  `cryptsetup luksUUID /dev/nvme0n1p2` with the UUID above, and check
  `cryptsetup luksDump /dev/nvme0n1p2 | grep -i pbkdf`.
- **GRUB rejects the passphrase.** GRUB uses a US keyboard layout.
- **Your password isn't accepted at the login screen.** Press
  **Ctrl+Alt+F3**, log in as `root` with root's password, and set a new one
  with `passwd user`.
- **No password works at all.** From the installer, unlock and mount the disk
  as shown below. Then edit `/mnt/etc/shadow` and empty root's password: the
  part between the first and second `:` on the line starting with `root:`.
  After rebooting, log in as `root` on Ctrl+Alt+F3 without a password and run
  `passwd` and `passwd user`.
- **The laptop runs out of memory or freezes during a build.** Check that
  `swapon --show` lists the swap file, and use `--cores=1`.
- **To get back into the installed disk from the installer**, for example to
  run step 5 again:

  ```sh
  cryptsetup open /dev/nvme0n1p2 cryptroot
  mount /dev/mapper/cryptroot /mnt
  mount /dev/nvme0n1p1 /mnt/boot/efi
  swapon /mnt/swapfile
  herd start cow-store /mnt
  ```
