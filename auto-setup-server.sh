#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then
	echo -e "Sorry, you need to run this as root"
	exit 1
fi

# Variables
NGINX_MAINLINE_VER=1.15.8
NGINX_STABLE_VER=1.14.2

clear
echo ""
echo "Welcome to the nginx-autoinstall script."
echo ""
echo "What do you want to do?"
echo "   1) Install or update Nginx"
echo "   2) Setup VHOSTS"
echo "   3) Setup SSL"
echo "   4) Exit"
echo ""

while [[ $OPTION !=  "1" && $OPTION != "2" && $OPTION != "3" && $OPTION != "4" ]]; do
	read -p "Select an option [1-4]: " OPTION
done
case $OPTION in
	1)
		echo ""
		echo "Do you want to install Nginx stable or mainline?"
		echo "   1) Stable $NGINX_STABLE_VER"
		echo "   2) Mainline $NGINX_MAINLINE_VER"
		echo ""
		while [[ $NGINX_VER != "1" && $NGINX_VER != "2" ]]; do
			read -p "Select an option [1-2]: " NGINX_VER
		done
		case $NGINX_VER in
			1)
			NGINX_VER=$NGINX_STABLE_VER
			;;
			2)
			NGINX_VER=$NGINX_MAINLINE_VER
			;;
		esac
		echo ""
		read -n1 -r -p "Nginx is ready to be installed, press any key to continue..."
		echo ""

		# Dependencies
		apt-get update
		apt-get install -y build-essential ca-certificates wget curl libpcre3 libpcre3-dev autoconf unzip automake libtool tar git libssl-dev zlib1g-dev uuid-dev lsb-release nginx

		# Nginx's cache directory is not created by default
		if [[ ! -d /var/cache/nginx ]]; then
			mkdir -p /var/cache/nginx
		fi

		# We add the sites-* folders as some use them.
		if [[ ! -d /etc/nginx/sites-available ]]; then
			mkdir -p /etc/nginx/sites-available
		fi
		if [[ ! -d /etc/nginx/sites-enabled ]]; then
			mkdir -p /etc/nginx/sites-enabled
		fi

		# Restart Nginx
		systemctl restart nginx

		# We're done !
		echo "Installation done."
	exit
	;;
	2) # Setup VHOSTS
		domain=$1
		rootPath=$2
		sitesEnable='/etc/nginx/sites-enabled/'
		sitesAvailable='/etc/nginx/sites-available/'
		serverRoot='/var/www/'
		domainRegex="^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$"

		while [ "$domain" = "" ]
		do
			echo "Please provide domain:"
			read domain
		done

		until [[ $domain =~ $domainRegex ]]
		do
			echo "Enter valid domain:"
			read domain
		done

		if [ -e $sitesAvailable$domain ]; then
			echo "This domain already exists. Please Try Another one"
			exit;
		fi


		if [ "$rootPath" = "" ]; then
			rootPath=$serverRoot$domain
		fi

		if ! [ -d $rootPath ]; then
			mkdir $rootPath
			chmod 777 $rootPath
			if ! echo "Hello, world!" > $rootPath/index.html
			then
				echo "ERROR: Not able to write in file $rootPath/index.html. Please check permissions."
				exit;
			else
				echo "Added content to $rootPath/index.html"
			fi
		fi

		if ! [ -d $sitesEnable ]; then
			mkdir $sitesEnable
			chmod 777 $sitesEnable
		fi

		if ! [ -d $sitesAvailable ]; then
			mkdir $sitesAvailable
			chmod 777 $sitesAvailable
		fi

		configName=$domain

		if ! echo "server {
			listen 80;
			root $rootPath;
			index index.php index.hh index.html index.htm;
			server_name $domain;
			location = /favicon.ico { log_not_found off; access_log off; }
			location = /robots.txt { log_not_found off; access_log off; }
			location ~* \.(jpg|jpeg|gif|css|png|js|ico|xml)$ {
				access_log off;
				log_not_found off;
			}
			location ~ \.(php|hh)$ {
				fastcgi_pass 127.0.0.1:9000;
				fastcgi_index index.php;
				include fastcgi_params;
				fastcgi_param HTTPS off;
			}
			location ~ /\.ht {
				deny all;
			}
			client_max_body_size 0;
		}" > $sitesAvailable$configName
		then
			echo "There is an ERROR create $configName file"
			exit;
		else
			echo "New Virtual Host Created"
		fi

		if ! echo "127.0.0.1	$domain" >> /etc/hosts
		then
			echo "ERROR: Not able write in /etc/hosts"
			exit;
		else
			echo "Host added to /etc/hosts file"
		fi

		ln -s $sitesAvailable$configName $sitesEnable$configName

		service nginx restart

		echo "Complete! You now have a new Virtual Host Your new host is: http://$domain And its located at $rootPath"
		exit;
	;;
	3) # setup ssl
		cd /
		if [ ! -f ./certbot-auto ]; then
			wget https://dl.eff.org/certbot-auto
		fi

	 	chmod a+x ./certbot-auto
	 	./certbot-auto

	 # We're done !
	 echo "Installation done."
	exit
	;;

esac