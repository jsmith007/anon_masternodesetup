#!/bin/bash
SCRIPT_VERSION=1.0.3
# Only run as a root user
if [ "$(sudo id -u)" != "0" ]; then
    echo "This script may only be run as root or with user with sudo privileges."
    exit 1
fi

HBAR="---------------------------------------------------------------------------------------"

# import messages
#source <(curl -sL https://gist.githubusercontent.com/doublesharp/bacf7f9ac1ff15dccc1acffe49f989e9/raw/messages.sh)
source anon_messages.sh



### Functions ###

pause(){
  echo ""
  read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}

do_exit(){
  echo ""
  echo "Install script (and donations welcomed) by:"
  echo ""
  echo "  jaysmeeth @ address INSERT ANON ADDRESS HERE"
  echo ""
  echo "Goodbye!"
  echo ""
  exit 0
}

update_system(){
  echo "$MESSAGE_UPDATE"
  # update package and upgrade Ubuntu
  sudo DEBIAN_FRONTEND=noninteractive apt -y update
  sudo DEBIAN_FRONTEND=noninteractive apt -y upgrade
  sudo DEBIAN_FRONTEND=noninteractive apt -y autoremove
  clear
}

maybe_prompt_for_swap_file(){
  # Create swapfile if less than 4GB memory
  MEMORY_RAM=$(free -m | awk '/^Mem:/{print $2}')
  MEMORY_SWAP=$(free -m | awk '/^Swap:/{print $2}')
  MEMORY_TOTAL=$(($MEMORY_RAM + $MEMORY_SWAP))
  if [ $MEMORY_TOTAL -lt 3500 ]; then
    echo ""
    echo "Server memory is less than 4GB... you will be able to compile Anon faster by creating a swap file."
    echo ""
    if ! grep -q '/swapfile' /etc/fstab ; then
      read -e -p "Do you want to create a swap file? [Y/n]: " CREATE_SWAP
      if [ "$CREATE_SWAP" = "" ] || [ "$CREATE_SWAP" = "y" ] || [ "$CREATE_SWAP" = "Y" ]; then
        IS_CREATE_SWAP="Y";
      fi
    fi
  fi
}

maybe_create_swap_file(){
  if [ "$IS_CREATE_SWAP" = "Y" ]; then
    echo "Creating a 4GB swapfile..."
    sudo swapoff -a
    sudo dd if=/dev/zero of=/swapfile bs=1M count=4096
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee --append /etc/fstab > /dev/null
    sudo mount -a
    echo "Swapfile created."
  fi
}

install_dependencies(){
  echo "$MESSAGE_DEPENDENCIES"
  # git
  sudo apt install -y git
  # build dependencies
  sudo apt-get install -y build-essential pkg-config libc6-dev m4 g++-multilib \
      autoconf libtool ncurses-dev unzip git python \
      zlib1g-dev wget bsdmainutils automake
  # build tools
  #sudo apt install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils software-properties-common
  # boost
  #sudo apt install -y libboost-all-dev
  # bdb 4.8
  #sudo add-apt-repository -y ppa:bitcoin/bitcoin
  #sudo apt install -y libdb4.8-dev libdb4.8++-dev
  # zmq
  #sudo apt install -y libzmq3-dev
  sudo apt update -y
  clear
}

git_clone_repository(){
  echo "$MESSAGE_CLONING"
  cd
  if [ ! -d ~/anon ]; then
    git clone  https://github.com/anonymousbitcoin/anon.git
  fi
}

anon_branch(){
  echo "Anon Branching not in use for now."
#  read -e -p "Anon Core Github Branch [master]: " ANON
#  if [ "$ANON_BRANCH" = "" ]; then
#    ANON_BRANCH="master"
#  fi
}

git_checkout_branch(){
  echo "Anon checkout branching not in use for now."
#  cd ~/anon
#  git fetch
#  git checkout $ANON_BRANCH --quiet
#  if [ ! $? = 0 ]; then
#    echo "$MESSAGE_ERROR"
#    echo "Unable to checkout https://www.github.com/anonymousbitcoin/anon/tree/${SYSCOIN_BRANCH}, please make sure it exists."
#    echo ""
#    exit 1
#  fi
#  git pull
}

autogen(){
echo "Autogen function not in use...for now."
echo "Future use could be for gening keys and addresses"
# Maybe use to make keys and node address
#  echo "$MESSAGE_AUTOGEN"
#  cd ~/anon
#  ./autogen.sh
#  clear
}


compile(){
  echo "$MESSAGE_MAKE"
  echo "Running compile with $(nproc) core(s)..."
  # compile using all available cores
  cd ~/anon
  ./anonutil/build.sh -j$(nproc)
 
  ./anonutil/fetch-params.sh
#  clear
}

make_install() {
  echo "$MESSAGE_MAKE_INSTALL"
  echo "Yeh Maybe in a future version for now, copying binaries into /usr/local/bin"
  # install the binaries to /usr/local/bin
  cd ~/anon
  sudo cp src/anond /usr/local/bin
  sudo cp src/anon-cli /usr/local/bin
  
#  sudo make install
#  clear
}


genkey() {
genkeyoutput=$(~/anon/src/anon-cli masternode genkey)
genkeyreturn="$?"
RETRY_YN="Y"
if [ "$genkeyreturn" != "0" ]; then
        echo "$genkeyoutput"
        read -e -p "Seems like something is not right.  Retry?" RETRY_YN
        if ["$RETRY_YN" == "y"] || ["$RETRY_YN" == "Y"]; then
                genkey
        else
                echo "Well I guess we are done here"
        fi
else
MASTERNODE_PRIVATE_KEY=$genkeyoutput
fi

}


masternode_private_key(){
  GEN_NEW_PRIV_KEY="y"
  read -e -p "Generate new Private Key for Masternode [y]/n: " GEN_NEW_PRIV_KEY
  if [ "$GEN_NEW_PRIV_KEY" == "y" ] || [ "$GEN_NEW_PRIV_KEY" == "Y" ]; then
     genkey
     masternodeprivkey="$(~/anon/src/anon-cli masternode genkey)"

     MASTERNODE_PRIVATE_KEY="$masternodeprivkey"
  else
        read -e -p "Masternode Private Key [$masternodeprivkey]: " MASTERNODE_PRIVATE_KEY
        if [ "$MASTERNODE_PRIVATE_KEY" = "" ]; then
                if [ "$masternodeprivkey" != "" ]; then
                        MASTERNODE_PRIVATE_KEY="$masternodeprivkey"
                else
                        echo "Hope you know what you are doing!  But im going to gen one for you anyway"
                        masternode_private_key
                fi
    fi
  fi
}



start_anond(){
  echo "$MESSAGE_ANOND"
  echo "Testing enable anon start around line 182"
  #sudo service anond start     # start the service
  #sudo systemctl enable anond  # enable at boot
  clear
}

stop_anond(){
  echo "$MESSAGE_STOPPING"
  sudo service anond stop
  clear
}


upgrade() {
  clear
  install_dependencies # make sure we have the latest deps
  update_system       # update all the system libraries
  git_checkout_branch # check out our branch
  clear
#  autogen             # run ./autogen.sh
#  configure           # run ./configure
  compile             # make and make install
  stop_anond       # stop syscoind if it is running
  make_install        # install the binaries

  # maybe upgrade sentinel
  if [ "$IS_UPGRADE_SENTINEL" = "" ] || [ "$IS_UPGRADE_SENTINEL" = "y" ] || [ "$IS_UPGRADE_SENTINEL" = "Y" ]; then
    install_sentinel
    install_virtualenv
    configure_sentinel
  fi

  install_anon_service
  start_anond      # start anond back up
  
  echo "$MESSAGE_COMPLETE"
  echo "Anon update complete using <Insert anon git path here>!"
  do_exit             # exit the script
}

create_and_configure_anon_user(){
  echo "$MESSAGE_CREATE_USER"

  # create a anon user if it doesn't exist
  grep -q '^anon:' /etc/passwd || sudo adduser --disabled-password --gecos "" anon
  
  # add alias to .bashrc to run anon-cli as anon user
  grep -q "anoncli\(\)" ~/.bashrc || echo "anoncli() { sudo su -c \"anoncoin-cli \$*\" anon; }" >> ~/.bashrc
  grep -q "alias anon-cli" ~/.bashrc || echo "alias anon-cli='anoncli'" >> ~/.bashrc
  grep -q "anond\(\)" ~/.bashrc || echo "sysd() { sudo su -c \"anond \$*\" anon; }" >> ~/.bashrc
  grep -q "alias anond" ~/.bashrc || echo "alias anond='anond'" >> ~/.bashrc

  #  grep -q "anonmasternode\(\)" ~/.bashrc || echo "anonmasternode() { bash <(curl -sL doublesharp.com/sysmasternode); }" >> ~/.bashrc

  echo "$ANON_CONF" > ~/anon.conf
  echo "$ANON_MASTERNODE_CONF" > ~/masternode.conf

  # in case it's already running because this is a re-install
  sudo service anond stop

  # create conf directory
  sudo mkdir -p /home/anon/.anon
  sudo rm -rf /home/anon/.anon/debug.log
  sudo mv -f ~/anon.conf /home/anon/.anon/anon.conf
  sudo chown -R anon.anon /home/anon/.anon
  sudo chmod 600 /home/anon/.anon/anon.conf
  clear
}

create_systemd_anond_service(){
  echo "$MESSAGE_SYSTEMD"
  # create systemd service
  echo "$ANOND_SERVICE" > ~/anond.service
  # install the service
  sudo mkdir -p /usr/lib/systemd/system/
  sudo mv -f ~/anond.service /usr/lib/systemd/system/anond.service
  # reload systemd daemon
  sudo systemctl daemon-reload
  clear
}

install_fail2ban(){
  echo "$MESSAGE_FAIL2BAN"
  sudo apt-get install fail2ban -y
  sudo service fail2ban restart
  sudo systemctl fail2ban enable
  clear
}

install_ufw(){
  echo "$MESSAGE_UFW"
  sudo apt-get install ufw -y
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow ssh
  sudo ufw allow 2222/tcp
  sudo ufw allow 8369/tcp
  yes | sudo ufw enable
  clear
}

get_masternode_status(){
  echo ""
  sudo su -c "anon-cli mnsync status" anon && \
  sudo su -c "anon-cli masternode status" anon
  echo ""
  read -e -p "Check again? [Y/n]: " CHECK_AGAIN
  if [ "$CHECK_AGAIN" = "" ] || [ "$CHECK_AGAIN" = "y" ] || [ "$CHECK_AGAIN" = "Y" ]; then
    get_masternode_status
  fi
}

masternode_create_address() {
	echo ""
	read -e -p "Do you already have a master node address? y/[n]" MN_ADDRESS_EXISTS
	if [ "MN_ADDRESS_EXISTS" == "y"] || ["MN_ADDRESS_EXISTS" == "Y"]; then
		read -e -p "Enter Master Node Collateral Address: " MASTERNODE_ADDRESS
	else
		MASTERNODE_ADDRESS = "$(~/anon/src/anon-cli masternode getaccountaddress 0)"
		echo "Send exactly 500 ANON to your masternode's address: $MASTERNODE_ADDRESS"		
	fi
}


# run time stuff below here

### MAIN Script Pass


clear
echo "$MESSAGE_WELCOME"
pause
clear

echo "$MESSAGE_PLAYER_ONE"
sleep 1
clear

### PROMPT FOR MasterNode Behaviour ###



# errors are shown if LC_ALL is blank when you run locale
if [ "$LC_ALL" = "" ]; then export LC_ALL="$LANG"; fi

# syscoind.service sentinel config
#SENTINEL_CONF=$(cat <<EOF
# syscoin conf location
#syscoin_conf=/home/syscoin/.syscoincore/syscoin.conf
# network
#EOF
#)



# check to see if there is already an anon user on the system
if grep -q '^anon:' /etc/passwd; then
  clear
  echo "$MESSAGE_UPGRADE"
  echo ""
  echo "  Choose [Y]es (default) to upgrade Anon on a working masternode."
  echo "  Choose [N]o to re-run the configuration process for your masternode."
  echo ""
  echo "$HBAR"
  echo ""
  read -e -p "Upgrade/recompile Anon? [Y/n]: " IS_UPGRADE
  if [ "$IS_UPGRADE" = "" ] || [ "$IS_UPGRADE" = "y" ] || [ "$IS_UPGRADE" = "Y" ]; then
    upgrade
  fi
fi
clear

RESOLVED_ADDRESS=$(curl -s ipecho.net/plain)

echo "$MESSAGE_CONFIGURE"
echo ""
echo "This script has been tested on Ubuntu 16.04 LTS x64."
echo ""
echo "Before starting script ensure you have: "
echo ""
echo " Yeh none of this. Infact it should all be changed...maybe later"
echo " Should probably put in the info about what if going to happen here"
#echo "  - Sent 100,000SYS to your masternode address"
	#echo "  - Run 'masternode genkey' and 'masternode outputs' and recorded the outputs" 
#echo "  - Added masternode config file ('Tools>Open Masternode Config' in Syscoin-Qt) "
#echo "    - addressAlias vpsIp:8369 masternodePrivateKey transactionId outputIndex"
#echo "    - EXAMPLE: mn1 ${RESOLVED_ADDRESS}:8369 ctk9ekf0m3049fm930jf034jgwjfk zkjfklgjlkj3rigj3io4jgklsjgklsjgklsdj 0"
#echo "  - Restarted Syscoin-Qt"
echo ""
echo "Default values are in brackets [default] or capitalized [Y/n] - pressing enter will use this value."
echo ""
echo "$HBAR"
echo ""

ANON_BRANCH="master"
DEFAULT_PORT=33130

# anon.conf value defaults
rpcuser="anonrpc"
rpcpassword="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
masternodeprivkey=""
externalip="$RESOLVED_ADDRESS"
port="$DEFAULT_PORT"

# try to read them in from an existing install
if sudo test -f /home/anon/.anon/anon.conf; then
  sudo cp /home/anon/.anon/anon.conf ~/anon.conf
  sudo chown $(whoami).$(id -g -n $(whoami)) ~/anon.conf
  source ~/anon.conf
  rm -f ~/anon.conf
fi

RPC_USER="$rpcuser"
RPC_PASSWORD="$rpcpassword"

#Generating Random Passwords
# why is this done twice?
#RPC_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

MASTERNODE_PORT="$port"

# ask which branch to use
# incase branches are a thing later
#anon_branch

if [ "$externalip" != "$RESOLVED_ADDRESS" ]; then
  echo ""
  echo "WARNING: The anon.conf value for externalip=${externalip} does not match your detected external ip of ${RESOLVED_ADDRESS}."
  echo ""
fi
read -e -p "External IP Address [$externalip]: " EXTERNAL_ADDRESS
if [ "$EXTERNAL_ADDRESS" = "" ]; then
  EXTERNAL_ADDRESS="$externalip"
fi
if [ "$port" != "" ] && [ "$port" != "$DEFAULT_PORT" ]; then
  echo ""
  echo "WARNING: The anon.conf value for port=${port} does not match the default of ${DEFAULT_PORT}."
  echo ""
fi
read -e -p "Masternode Port [$port]: " MASTERNODE_PORT
if [ "$MASTERNODE_PORT" = "" ]; then
  MASTERNODE_PORT="$port"
fi

# read -e -p "Configure for mainnet? [Y/n]: " IS_MAINNET

maybe_prompt_for_swap_file

pause
clear

# do compile and build

# if there is <4gb and the user said yes to a swapfile...
maybe_create_swap_file

# prepare to build
###update_system
###install_dependencies
###git_clone_repository
#no branching for now
#git_checkout_branch
#clear

# run the build steps
echo "RUNNING COMPILE"
###compile
###make_install
#clear

#create temp anon.conf file

ANON_CONF=$(cat <<EOF
rpcuser=anonrpc
rpcpassword=set-a-password
rpcallowip=127.0.0.1
txindex=1
EOF
)

mkdir -p ~/.anon
echo "$ANON_CONF" > ~/.anon/anon.conf
~/anon/src/anond -daemon

masternode_private_key
masternode_create_address

echo "Node Collateral address: $MASTERNODE_ADDRESS"
echo "Send exactly 500.0 ANON to the address above in a single transaction"

read -e -p "Has the 500 ANON collateral been sent? And do you have the transaction id? PresS Enter to continue" 
read -e -p "Enter the transaction id from the transfer:" TRANSACTION_ID
echo "Masternode Transaction output: $(~/anon/src/anon-cli masternode outputs)"
echo "If no or empty output, use 0 for the transaction index. And update masternode.conf entry later with the correct number"
read -e -p "Enter transaction index (0 or 1):" COLLATERAL_INDEX


# put up system config files

### need masternode private key
### so cant do until after compile

#### CONFIG FILE VARIABLES ####
# anon conf file
ANON_CONF=$(cat <<EOF
# rpc config
rpcuser=anonrpc
rpcpassword=$RPC_PASSWORD
rpcallowip=127.0.0.1
rpcbind=127.0.0.1
txindex=1
EOF
)

ANON_MASTERNODE_CONF=$(cat <<EOF
# Masternode config file
# Format: alias IP:port masternodeprivkey collateral_output_txid collateral_output_index
$NODEALIAS $EXTERNAL_ADDRESS:$MASTERNODE_PORT $MASTERNODE_PRIVATE_KEY $TRANSACTION_ID $COLLATERAL_INDEX
EOF
)

# anond.service config
ANOND_SERVICE=$(cat <<EOF
[Unit]
Description=Anon Service
After=network.target iptables.service firewalld.service
 
[Service]
Type=forking
User=anon
ExecStart=/usr/local/bin/anond -daemon
ExecStop=/usr/local/bin/anon-cli stop && sleep 20 && /usr/bin/killall anond
ExecReload=/usr/local/bin/anon-cli stop && sleep 20 && /usr/local/bin/anond
 
[Install]
WantedBy=multi-user.target
EOF
)

create_and_configure_anon_user
create_systemd_anond_service
/usr/bin/killall anond

start_anond

### Wrap Up ###
install_fail2ban
install_ufw
clear

echo "$MESSAGE_COMPLETE"
echo ""
echo "Your masternode configuration should now be completed and running as the anon user."
#echo "If you see MASTERNODE_SYNC_FINISHED return to Syscoin-Qt and start your node, otherwise check again."

echo "Testing enable get_master_node_status near line 531"
#get_masternode_status

# ping sentinel
#sudo su -c "sentinel-ping" anon

echo ""
echo "Masternode setup complete!"
echo ""
echo "Please run the following command to access anon-cli from this session or re-login."
echo ""
echo "  source ~/.bashrc"
echo ""
echo "You can run anon-cli commands as the anon user: "
echo ""
echo "  anon-cli getinfo"
echo "  anon-cli masternode status"
echo ""
echo "To update this masternode just type:"
echo ""
echo "  anonmasternode"
echo ""
echo "Master Node information"
echo "Private key: "
echo "Node Collateral address: "
echo "Send 500 ANON to the address above or this was for not"
echo ""
echo "Once that is completed then"

do_exit
