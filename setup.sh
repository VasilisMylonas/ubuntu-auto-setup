#!/usr/bin/env bash

TEMP_DIR=./temp
DOTFILE_DIR=./dotfiles
THEME_URL="https://github.com/vinceliuice/vimix-gtk-themes/archive/2020-11-28.tar.gz"
ICONS_URL="https://github.com/vinceliuice/vimix-icon-theme/archive/2020-07-10.tar.gz"
CHROME_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

spinner() {
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $!)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep 0.25
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

create_temp_dir() {
    if [ ! -d "$TEMP_DIR" ]; then
        mkdir $TEMP_DIR
    elif [ "$(ls -A $DIR)" ]; then
        echo "Error: Temp directory not empty."
        exit -1
    fi
}

install_pack() {
    wget $1 -q -O $TEMP_DIR/$2.tar.gz
    tar -xf $TEMP_DIR/$2.tar.gz -C $TEMP_DIR/$2
    rm $TEMP_DIR/$2.tar.gz
    chmod +x $TEMP_DIR/$2/install.sh
    sudo $TEMP_DIR/$2/install.sh
    rm -rf $TEMP_DIR/$2
}

install_deb() {
    wget $1 -q -O $TEMP_DIR/$2.deb
    sudo dpkg -i $TEMP_DIR/$2.deb
    rm $TEMP_DIR/$2.deb
}

install_template() {
    echo -e $1 > "$HOME/Templates/$2" && chmod +x "$HOME/Templates/$2"
}

install_dotfiles() {
    for f in $DOTFILE_DIR/*; do
        cp $f $HOME
    done
}

install_programs() {
   sudo add-apt-repository -y ppa:lutris-team/lutris &> /dev/null
   sudo apt update &> /dev/null
   sudo apt upgrade -y &> /dev/null

   local packages=$(tr "\n" " " < "./packages.list")
   local snaps=$(tr "\n" " " < "./snaps.list")

   sudo apt install -y $packages &> /dev/null & spinner
   sudo snap install -y $snaps &> /dev/null & spinner
}

# Make sure we are not running as root.
if [ $EUID -eq 0 ]; then
    echo "Error: Don't run this script as root. Try again without sudo."
    exit -1
fi

create_temp_dir
echo "[1/7] Created temp directory."

install_programs
echo "[2/7] Installed packages from programs.list and snaps.list"

# Connect vimix for snaps.
for i in $(snap connections | grep gtk-common-themes:gtk-3-themes | awk '{print $2}'); do
    sudo snap connect $i vimix-themes:gtk-3-themes
done

install_pack $ICONS_URL "icons"
echo "[3/7] Installed icons theme."

install_pack $THEME_URL "theme"
echo "[4/7] Installed theme."

install_deb $CHROME_URL "chrome"
echo "[5/7] Installed Google Chrome."

install_template "" "Text File.txt"
install_template "#!/usr/bin/env bash\n\n" "Bash Script.bash"
install_template "#!/usr/bin/env python3\n\n" "Python Script.py"
install_template "#!/usr/bin/env ruby\n\n" "Ruby Script.rb"
echo "[6/7] Installed file templates."

install_dotfiles
echo "[7/7] Installed dotfiles."

# Install oh my zsh
sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

echo "All done and dusted!"