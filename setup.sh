#!/usr/bin/env bash

TEMP_DIR=./temp
DOTFILE_DIR=./dotfiles
THEME_URL="https://github.com/vinceliuice/vimix-gtk-themes/archive/2020-11-28.tar.gz"
ICONS_URL="https://github.com/vinceliuice/vimix-icon-theme/archive/2020-07-10.tar.gz"
CHROME_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

spinner() {
    printf "$1..."
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $!)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep 0.25
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b\b\b\b [Done]\n"
}

create_temp_dir() {
    if [ ! -d "$TEMP_DIR" ]; then
        mkdir $TEMP_DIR
    elif [ "$(ls -A $TEMP_DIR)" ]; then
        echo "Error: Temp directory not empty."
        exit 1
    fi
}

install_pack() {
    wget $1 -qO $TEMP_DIR/$2.tar.gz &&
    tar -xf $TEMP_DIR/$2.tar.gz -C $TEMP_DIR &&
    rm $TEMP_DIR/$2.tar.gz &&
    mv $TEMP_DIR/vimix-* $TEMP_DIR/$2
    chmod +x $TEMP_DIR/$2/install.sh &&
    sudo $TEMP_DIR/$2/install.sh &> /dev/null &&
    rm -rf $TEMP_DIR/$2
}

install_deb() {
    wget $1 -qO $TEMP_DIR/$2.deb &&
    sudo dpkg -i $TEMP_DIR/$2.deb &> /dev/null &&
    rm $TEMP_DIR/$2.deb
}

create_template() {
    echo -e $1 > "$HOME/Templates/$2" && chmod +x "$HOME/Templates/$2"
}

install_dotfiles() {
    for f in $DOTFILE_DIR/*; do
        cp $f $HOME
    done
}

update_sources() {
    for l in $(cat ./sources.list); do
        sudo add-apt-repository -y $l  &> /dev/null
    done

    sudo apt update &> /dev/null
    sudo apt upgrade -y &> /dev/null
}

create_templates() {
    create_template "" "Text File.txt"
    create_template "#!/usr/bin/env bash\n\n" "Bash Script.bash"
    create_template "#!/usr/bin/env python3\n\n" "Python Script.py"
    create_template "#!/usr/bin/env ruby\n\n" "Ruby Script.rb"
}

install_list() {
   sudo $1 install -y $(tr "\n" " " < "./$1.list") &> /dev/null
}

test_network() {
    ping -q -c 3 google.com &> /dev/null

    if [ $? -ne 0 ]; then
        echo "Error: Could not connect. Are you connected to the internet?"
        exit 1
    fi
}

test_permissions() {
    # Make sure we are not running as root.
    if [ $EUID -eq 0 ]; then
        echo "Error: Don't run this script as root. Try again without sudo."
        exit 1
    fi

    # Dummy sudo
    sudo true
}

test_network
test_permissions
create_temp_dir
echo "This may take some time. Grab a snack."

update_sources & spinner "Updating sources"
install_list "apt" & spinner "Installing packages from apt.list"
install_list "snap" & spinner "Installing snaps from snap.list"

# Connect vimix for snaps.
for i in $(snap connections | grep gtk-common-themes:gtk-3-themes | awk '{print $2}'); do
    sudo snap connect $i vimix-themes:gtk-3-themes &> /dev/null
done

install_pack $ICONS_URL "icons" & spinner "Installing icon theme"
install_pack $THEME_URL "theme" & spinner "Installing app theme"
install_deb $CHROME_URL "chrome" & spinner "Installing Google Chrome"
create_templates & spinner "Creating file templates"
install_dotfiles & spinner "Copying dotfiles"

# Install oh my zsh
sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

rmdir $TEMP_DIR

echo "All done and dusted!"