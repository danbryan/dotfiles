#!/bin/bash
exec 2> ~/workspace_bootstrap.log  # send stderr from to a log file
exec 1>&2                      # send stdout to the same log file
set -ex                         # tell sh to display commands before execution

if [[ $EUID -eq 0 ]]; then
   echo "Do not run as root." 
   exit 1
fi

if ! sudo yum repolist | grep epel\/x86_64 ; then
   # Enable epel
   sudo amazon-linux-extras install -y epel
   sudo yum-config-manager --setopt=epel.priority=5 --save
   sudo yum -y update
fi

#Install cli tools.
packages=( 
    jq # Git Easy
    nmap # nmap
    openldap-clients # ldapsearch
    htop # process manager
)
for package in "${packages[@]}"
do
    if ! command -v $package ; then
        sudo yum install -y $package
    fi
done


#Install VS Code Repository.
if ! command -v code ; then
    echo "### Installing VSCODE..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo yum install -y code openssh-askpass git

else
    echo "### VSCODE Already Installed"
fi

# Install VS Code Extensions
echo "### Installing VSCODE Extenions"
extensions=( 
    bibhasdn.git-easy # Git Easy
    eamodio.gitlens # Git Lens
    felipecaputo.git-project-manager # Git Package Manager
    korekontrol.saltstack #Salt Stack
    eastman.vscode-cfn-nag # CFN Nag
    kddejong.vscode-cfn-lint #CFN Lint
    eriklynd.json-tools # JSON Tools
    mohsen1.prettify-json # Prettify JSON
    foxundermoon.shell-format # Shell Format
    hoovercj.vscode-power-mode # Power Mode
    mark-tucker.aws-cli-configure #AWS CLI Configure
    mitchdenny.ecdc # Encode Decode
    mkloubert.vscode-remote-workspace # Remote Workspace
    ms-python.python # Python
    ms-vscode.Go # Go
    ms-vscode.PowerShell # Powershell
    yzhang.markdown-all-in-one # Markdown
    pkief.material-icon-theme # Material Icon Theme
    equinusocio.vsc-material-theme # Material Theme
)

for i in "${extensions[@]}"
do
    code --install-extension $i
done

#Install Chrome Repository
if ! command -v google-chrome-stable ; then
    echo "### Installing Google Chrome..."
    sudo rpm --import https://dl-ssl.google.com/linux/linux_signing_key.pub
    sudo sh -c 'echo -e "[google-chrome]\nname=google-chrome\nbaseurl=http://dl.google.com/linux/chrome/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\ngpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub" > /etc/yum.repos.d/google-chrome.repo'
    sudo yum install -y google-chrome-stable
else
    echo "### Google Chrome Already Installed"
fi

#install Google Golang
if ! command -v /usr/local/go/bin/go ; then
    echo "### Installing Google Golang..."
    GOURLREGEX='https://dl.google.com/go/go[0-9\.]+\.linux-amd64.tar.gz'
    echo "Finding latest version of Go for AMD64..."
    url="$(wget -qO- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n 1 )"
    latest="$(echo $url | grep -oP 'go[0-9\.]+' | grep -oP '[0-9\.]+' | head -c -2 )"
    echo "Downloading latest Go for AMD64: ${latest}"
    curl -O "$url"
    unset url
    unset GOURLREGEX
    sudo tar -C /usr/local -xzf go"${latest}".linux-amd64.tar.gz
    mkdir -p ~/go/{bin,pkg,src}
    echo "Setting up GOPATH"
    echo "export GOPATH=~/go" >> ~/.profile && source ~/.profile
    echo "Setting PATH to include golang binaries"
    echo "export PATH='$PATH':/usr/local/go/bin:$GOPATH/bin" >> ~/.profile && source ~/.profile
else
    echo "### Google Golang Already Installed"
fi

if ! command -v terraform ; then
    echo "### Installing terraform"
    url="$(echo "https://releases.hashicorp.com/terraform/$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version')/terraform_$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version')_linux_amd64.zip")"
	curl "$url" -o "tf.zip"
	unzip -o tf.zip -d ~/.local/bin/
	ln -sf ~/.local/bin/terraform ~/.local/bin/tf
else
    echo "### Terraform Already Installed"
fi

# Install PAC Manager
if ! command -v pac ; then
    echo "### Installing PAC Manager"
    wget http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
    sudo yum install -y xfreerdp
    sudo yum install -y nux-dextop-release-0-5.el7.nux.noarch.rpm
    sudo yum install -y pac perl-Digest-SHA perl-XML-Parser perl-Gnome2-Vte
    sudo find /opt/pac -name Vte.so* -exec rm {} \;
else
    echo "### PAC Manager Already Installed"
fi

# Install Ruby
if ! command -v ruby ; then
   echo "### Installing Ruby"
   sudo yum install -y gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison iconv-devel sqlite-devel
   curl -sSL https://rvm.io/mpapis.asc | gpg --import -
   curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
   curl -L get.rvm.io | bash -s stable
   set +e
   source ~/.rvm/scripts/rvm
   rvm reload
   rvm install 2.6
   rvm use 2.6 --default
   ruby --version
   echo 'source ~/.rvm/scripts/rvm' >> ~/.bashrc
   echo 'rvm use 2.6 --default' >> ~/.bashrc
   source ~/.bashrc
   set -e
else
   echo "### Ruby Already Installed"
fi
# Install Gems
gems=(
    cfn-nag # CFN Nag
)
for gem in "${gems[@]}"
do
   gem install "$gem"
done

# Install Python 3
if ! command -v python3.6 ; then
    echo "### Installing Python3"
	sudo yum install -y python36 python36-pip python36-devel.x86_64
else
    echo "### Python3 Already Installed"
fi

# Install pip packages
sudo pip3.6 install --upgrade pip
set +e
echo 'export PATH="~/.local/bin:$PATH"' >> ~/.profile && source ~/.profile
set -e
packages=(
    awscli # AWS Cli
    boto3 # Boto3
    cfn-lint # CFN Lint
    pylint # Python Lint
    aws-sam-translator # SAM Translator
)
for package in "${packages[@]}"
do
    pip3 install --upgrade "$package" --user
done


#Update sudoers for ws admin.
__USER="$(whoami | cut -d '\' -f2)"
__DOMAIN="$(dnsdomainname)"
__ID="$(id $__DOMAIN\\$__USER -u)"

if [[ $EUID -eq 0 ]]; then
   echo "root doesn't need sudo, consider running as a normal user." 
   exit 1
fi
if ! sudo grep -qF "NOPASSWD:ALL" /etc/sudoers.d/01-ws-admin-user; then
    echo '#'$__ID 'ALL=(ALL:ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/01-ws-admin-user
fi

# Install Cinnamon Desktop
if ! command -v cinnamon ; then
sudo yum install cinnamon -y
sudo sed -i 's/mate/cinnamon/g' /etc/pcoip-agent/pcoip-agent.conf
else
    echo "### Cinnamon Already Installed"
fi

settings=$(cat <<EOF
{
    "window.zoomLevel": -1,
    "workbench.startupEditor": "newUntitledFile",
    "workbench.colorTheme": "Material Theme Darker",
    "workbench.colorCustomizations": {
        "editor.background": "#000000",
        "sideBar.background": "#000000",
        "terminal.background": "#000000",
        "activityBarBadge.background": "#388E3C",
        "list.activeSelectionForeground": "#388E3C",
        "list.inactiveSelectionForeground": "#388E3C",
        "list.highlightForeground": "#388E3C",
        "scrollbarSlider.activeBackground": "#388E3C50",
        "editorSuggestWidget.highlightForeground": "#388E3C",
        "textLink.foreground": "#388E3C",
        "progressBar.background": "#388E3C",
        "pickerGroup.foreground": "#388E3C",
        "tab.activeBorder": "#388E3C",
        "notificationLink.foreground": "#388E3C",
        "editorWidget.resizeBorder": "#388E3C",
        "editorWidget.border": "#388E3C",
        "settings.modifiedItemIndicator": "#388E3C",
        "settings.headerForeground": "#388E3C",
        "panelTitle.activeBorder": "#388E3C",
        "breadcrumb.activeSelectionForeground": "#388E3C",
        "menu.selectionForeground": "#388E3C",
        "menubar.selectionForeground": "#388E3C"
    },
    "go.inferGopath": true,
    "git.defaultCloneDirectory": "~/code",
    "gitProjectManager.baseProjectsFolders": [
        "~/code"
    ],
    "editor.minimap.enabled": false,
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "workbench.iconTheme": "material-icon-theme",
    "files.associations": {
        "*.template": "yaml",
        "*.cft": "yaml"
    },
    "explorer.confirmDelete": false,
    "materialTheme.accent": "Breaking Bad",
    "powermode.enabled": true,
    "powermode.presets": "flames",
    "terminal.integrated.fontSize": 15,
    "git.autofetch": true,
    "explorer.confirmDragAndDrop": false
}
EOF
)
mkdir -p ~/.config/Code/User/
echo "$settings" > ~/.config/Code/User/settings.json
