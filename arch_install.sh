# Alipio's RIcing Script for Arch
#part1
printf '\033c'
echo "Welcome to Alipio's RIcing Script for Arch"
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
loadkeys us
timedatectl set-ntp true
lsblk
printf "\e[0;36mEnter the disk: \e[0m"
read disk
printf "\e[0;36mEnter root partition size in GB: \e[0m"
read rootsz
printf "\e[0;36mEnter swap partition size in GB: \e[0m"
read swapsz
cat <<EOF | fdisk $disk
o
n
p


+200M
n
p


+${swapsz}G
n
p


+${rootsz}G
n
p


w
EOF
partprobe
echo "Formatting and mounting partitions..."
yes | mkfs.ext4 "${disk}4"
yes | mkfs.ext4 "${disk}3"
yes | mkfs.ext4 "${disk}1"
mkswap "${disk}2"
swapon "${disk}2"
mount "${disk}3" /mnt
mkdir -p /mnt/boot
mount "${disk}1" /mnt/boot
mkdir -p /mnt/home
mount "${disk}4" /mnt/home
echo "Installing base system..."
pacstrap /mnt base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
echo $disk >/mnt/disk.tmp
sed '1,/^#part2/d' arch_install.sh >/mnt/arch_install2.sh
chmod +x /mnt/arch_install2.sh
echo "Running chroot script..."
arch-chroot /mnt ./arch_install2.sh
rm /mnt/arch_install2.sh
exit

#part2
printf '\033c'
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/;/^#Color$/s/#//" /etc/pacman.conf
sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
printf "\e[0;36mHostname: \e[0m"
read hostname
echo $hostname > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts
passwd
pacman --noconfirm -S grub
grub-install --target=i386-pc $(cat disk.tmp)
rm disk.tmp
sed -i 's/quiet/pci=noaer/g' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S --noconfirm adobe-source-code-pro-fonts arandr atool bat bc ctags curl dash \
  dosfstools dunst exfat-utils feh ffmpeg ffmpegthumbnailer fzf git gnome-epub-thumbnailer \
  gnome-keyring imagemagick inetutils jq libffi libnotify libyaml man-db mediainfo mlocate \
  moreutils mpv ncdu networkmanager noto-fonts noto-fonts-emoji ntfs-3g openssh pacman-contrib \
  pipewire-pulse polkit pulsemixer ripgrep rsync scrot slock stow sxiv syncthing transmission-cli \
  ttf-dejavu ttf-linux-libertine unclutter unrar unzip vim wireplumber xclip xcompmgr xdotool \
  xorg-server xorg-xbacklight xorg-xev xorg-xinit xorg-xprop xorg-xsetroot xorg-xwininfo xwallpaper \
  yt-dlp zathura zathura-cb zathura-pdf-mupdf zip

systemctl enable NetworkManager
rm /bin/sh
ln -s dash /bin/sh
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
printf "\e[0;36mEnter Username: \e[0m"
read username
useradd -m -G wheel -s /bin/bash $username
passwd $username
echo "Pre-installation complete"
ai3_path=/home/$username/arch_install3.sh
sed '1,/^#part3/d' arch_install2.sh > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/bash $username
rm $ai3_path
exit

#part3
printf '\033c'
mkdir -p ~/.cache ~/.config ~/.local ~/proj
rm -f ~/.bashrc ~/.bash_profile ~/.bash_logout

cd ~/proj
git clone https://github.com/alipio/dotfiles.git
stow dotfiles
cd

# dwm: window Manager
git clone --depth=1 https://github.com/alipio/dwm.git ~/proj/dwm
sudo make -C ~/proj/dwm install

# st: terminal
git clone --depth=1 https://github.com/alipio/st.git ~/proj/st
sudo make -C ~/proj/st install

# dwmblocks: statusbar
git clone --depth=1 https://github.com/alipio/dwmblocks.git ~/proj/dwmblocks
sudo make -C ~/proj/dwmblocks install

# dmenu: dynamic menu
git clone --depth=1 https://github.com/alipio/dmenu.git ~/proj/dmenu
sudo make -C ~/proj/dmenu install

# keyd config: key remapping daemon
sudo curl -fLo /etc/keyd/default.conf --create-dirs \
  https://raw.githubusercontent.com/alipio/keyd-config/master/default.conf

# paru: AUR helper
git clone https://aur.archlinux.org/paru-bin.git && cd paru-bin && makepkg -sri && cd .. && rm -rf paru-bin
paru -S --noconfirm asdf-vm diff-so-fancy-git gtk-theme-arc-gruvbox-git \
  htop-vim keyd-git librewolf-bin simple-mtpfs task-spooler

sudo systemctl enable keyd
mkdir -p dl doc pics music
touch ~/.tool-versions

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +qa

eval "$(grep '^export' ~/.profile)"
. "$ASDF_DIR/asdf.sh"
asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf install ruby latest
asdf global ruby latest
gem update --system
bundle config --global jobs $(nproc)
exit
