#!/bin/bash

if [ "$(id -u)" != 0 ]
then
	echo "Root permissions required" >&2
	exit 1
fi

RED='\033[1;33m'
NC='\033[0m' # No Color

project_type=""
certificate=""

echo $'Creating deploy files.\n'

set_domain() {
	read -p $"Print the domain (localhost): " domain

	if [ "$domain" = "" ]
		then
			domain="localhost"
			echo "domain is $domain"
	fi
}

file_exists() {
	read -p "$1 already exists, continue? (y/yes or n/no): " continue

	if [ $continue = "yes" -o $continue = "y" ]
	then
		$2
	elif [ $continue = "no" -o $continue = "n" ]
	then
		echo "Program is finished."
		exit 0;
	else
		echo "Invalid option, try again."
		file_exists "$1" "$2"
	fi
}

set_certificate() {
	read -p "Create certificate? (y/yes or n/no): " certificate

	if [ $certificate = "yes" -o $certificate = "y" ]
	then
		certbot_run "dry"
		certbot_run
	elif [ $certificate = "no" -o $certificate = "n" ]
	then
		echo "Ok."
	else
		echo "Invalid option, try again."
		set_certificate
	fi
}

set_nginx() {
	case "$project_type" in
		1)
			nginxfile=$(curl https://raw.githubusercontent.com/aigen31/lemp-configs/main/wp/example.com.wordpress.conf)
			echo "project is wordpress"
		;;
		2)
			nginxfile=$(curl https://raw.githubusercontent.com/aigen31/lemp-configs/main/php/example.com.conf)
			echo "project is git"
		;;
		3)
			nginxfile=$(curl https://raw.githubusercontent.com/aigen31/lemp-configs/main/php/example.com.conf)
			echo "project is php"
		;;
	esac
	
	configpath=$PWD/docker/backend/nginx/conf/$domain.conf

	replace() {
		replace=${nginxfile//example.com/$domain}
		echo "$replace" > "$configpath"
		chown -R 1000:1000 "$configpath"
		chmod 755 "$configpath"
	}

	if [ ! -f "$configpath" ]
	then
		replace
	else
		file_exists "$configpath" replace
	fi
}

certbot_run() {
	if [$1 = "dry"]
	then
		docker-compose -f compose.certbot.yml run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ --dry-run -d $domain
	elif [ -z $2 ]
	then
		echo "This function can't has more than two arguments"
	else
		docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d $domain
	fi
}

docker_exec() {
	docker-compose exec $1 $2
}

make_dir() {
	mkdir $PWD/docker/backend/www/$domain
}

install_wp() {
	set_domain
	set_nginx
	set_certificate

	wp_cli() {
		docker_exec "php-main" "wp core download --path=$domain --locale=ru_RU --allow-root"
		chown -R www-data:www-data $PWD/docker/backend/www/$domain
		chmod -R 775 $PWD/docker/backend/www/$domain
	}

	if [ ! -d "$PWD/docker/backend/www/$domain" ]
	then
		make_dir
		wp_cli
	else
		file_exists $domain wp_cli
	fi

	echo -e "${RED}After finishig of Wordpress configuration you should to change file and directories permissions like a follow line:\n\nchown www-data:www-data -R ./www\nfind ./www -type d -exec chmod 755 {} \; \nfind ./www -type f -exec chmod 644 {} \;${NC}"
}

install_git() {
	set_domain
	set_nginx

	read -p $"Link to repository: " git

	cd $PWD/docker/backend/www

	sudo -u $SUDO_USER bash -c "git clone $git $domain"
}

install_php() {
	set_domain
	set_nginx
	make_dir
}

PS3=$'\nSelect the project type: '

select number in "Wordpress" "Git project" "Empty PHP" "Create the SSL certificate" "Exit"
do
	case $number in
		"Wordpress")
			project_type=1
			install_wp
			break
		;;
		"Git project")
			project_type=2
			install_git
			break
		;;
    "Empty PHP")
			project_type=3
			install_php
			break
		;;
    "Create the SSL certificate")
			set_certificate
			break
		;;
		"Exit")
			exit 0
		;;
		*) echo "Invalid option";;
	esac
done
