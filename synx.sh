#!/usr/bin/env bash
FILE=/root/mn_count
WALLET=https://github.com/SyndicateLtd/SyndicateQt/releases/download/v2.1.0/
FILENAME=Syndicate-2.1.0-linux64.zip
BOOTSTRAP=http://209.250.239.190/bootstrap2.zip
vpsip=$(hostname -I | awk '{print $1}')
mncount=$(cat $FILE)
declare CONFIRM_SUMMARY=Y

clear
if [[ $(whoami) != 'root' ]]; then
	echo 'You must be root to use this script.'
	exit 1
fi

declare AGREE=Y
declare CONFIRM=Y

function ask_yn() {
	question="$1"
	# also return result to this var
	default_answer=${!2}
	while true; do
		
		
		read -p "$question [y/n]: " REPLY
		if [ -z "$REPLY" ]; then
			REPLY="$default"
		fi
		
		case "$REPLY" in
			Y*|y*)
				eval $2=Y
				return 0;;
			N*|n*)
				eval $2=N
				return 1;;
		esac
	done
}



function mn_summary() {
	echo 'MN Configuraton Summary:'
	echo "#------------------"
	echo "rpcuser=$usrnammn1"
	echo "rpcpassword=$usrpasmn1"
	echo "rpcallowip=127.0.0.1"
	echo "#------------------"
	echo "server=1"
	echo "listen=1"
	echo "daemon=1"
	echo "logtimestamps=1"
	echo "maxconnections=256"
	echo "#------------------"
	echo "mnconflock=1"
	echo "masternode=1"
	echo "externalip=$vpsip"
	echo "masternodeprivkey=$privkeymn1"

}


if [ -f $FILE ];
then
   echo "At least one masternode is present, you cannot set up another one on same server"
   exit
else
   echo "Configuring first masternode"
	echo "1" >> $FILE
#create swap			
	fallocate -l 3G /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile
	echo -e "/swapfile   none    swap    sw    0   0 \n" >> /etc/fstab
#update system and install required packages
	sudo ufw allow OpenSSH
	(crontab -u root -l; echo "@reboot  /usr/local/bin/syndicated" ) | crontab -u root -
	sudo ufw allow 25992
	sudo ufw allow 25993
	sudo ufw default deny incoming
	sudo ufw default allow outgoing
	sudo ufw --force enable
	sudo apt-get update -y
	sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
	sudo apt-get install fail2ban unzip -y
	sudo apt upgrade -y
	sudo apt autoremove -y
        mkdir .syndicate
#download syndicated and bootstrap
	cd /opt
	mkdir temp
	cd temp
	wget $WALLET$FILENAME
	unzip $FILENAME -d /usr/local/bin/
	chmod 777 /usr/local/bin/*
	wget $BOOTSTRAP -O boot.zip
	sudo unzip -o /opt/temp/boot.zip -d ~/.syndicate/
#setup on root rpc access
	clear
		while true; do
			echo -e "Key In a User Name for MN access (same as in wallet) \n"
			echo -e "You can find it in Windows wallet PC under this location\n"
			echo -e "click start and type in %appdata%/syndicate and enter, edit syndicate.conf file\n"
			echo -e "Please key in rpcuser here and press [ENTER]:\n"
			read usrnammn1
			echo -e "Key In a MN PASSWORD (same as in your wallet) can be found in same file as before: \n"
			echo -e "Please key in rpcpassword here and press [ENTER]:\n"
			read usrpasmn1
			echo -e "SYNX must use port 25992\n"
			sleep 2
			echo -e "Key In the Masternode privatekey and press[ENTER]: \n"
			echo -e "This is the output from masternode genkey command: \n"
			read privkeymn1
			clear
			mn_summary
				if ask_yn 'Is this correct?' 'CONFIRM_SUMMARY'; then
				break
				fi
		done
	sudo echo -e "rpcuser=$usrnammn1\nrpcpassword=$usrpasmn1\nrpcallowip=127.0.0.1\n#----\nlisten=1\nserver=1\ndaemon=1\nlogtimestamps=1\nmaxconnections=256\n#------------------\nmasternode=1\nmaxconnections=1024\nmasternodeprivkey=$privkeymn1\nexternalip=$vpsip\nbind=$vpsip\nexternalip=$vpsip:25992\n#-----------------\naddnode=45.76.61.67:25992\naddnode=217.72.87.70:25992\naddnode=45.32.222.55:25992\naddnode=108.61.215.254:25992\n" > ~/.syndicate/syndicate.conf
	syndicated &
	echo "Wait 10 sec"
	sleep 10
	syndicate-cli getblockcount
	echo "Note block number, it should increase on next screen"
	sleep 10
	syndicate-cli getblockcount
	sleep 10
fi	
clear

echo -e "\nScript complete and masternode is synchonizing\n"
echo -e "Now execute following commands in this order\n"
echo -e "syndicate-cli getblockcount\n"
echo -e "Repeat until fully synced\n"
echo -e "Press start masternode on your wallet PC\n"
echo -e "syndicate-cli masternode status\n"
echo -e "Status code should be 4 with message Masternode successfully started\n"
echo -e "Rewards should start coming in after 3-5 days from set-up\n"

echo -e "\n Please consider donating to: Sdj95FWteZ9ArJw6tKq7yANRkdaZ2EB4nP "





