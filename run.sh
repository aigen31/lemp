#!/bin/bash

if [ "$(id -u)" != 0 ]
then
	echo "Root permissions required" >&2
	exit 1
fi

RED='\033[1;33m'
NC='\033[0m' # No Color

echo $'Creating deploy files.\n'

set_domain() {
	read -p $"Print the domain: " domain
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

set_nginx() {
	nginxfile=$(cat $PWD/examples/nginx.conf)
	configpath=$PWD/nginx/conf/$domain.conf

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
		docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ --dry-run -d $domain
	elif [ -z $2 ]
	then
		echo "This function can't has more than two arguments"
	else
		docker-compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d $domain
	fi
}

# yes_no() {
# 	if [ $1 = "yes" -o $1 = "y" ]
# 	then
# 		$2
# 	elif [ $1 = "no" -o $1 = "n" ]
# 	then
# 		echo "Завершение программы."
# 		exit 0;
# 	else
# 		read -p "Неверный вариант, попробуйте ещё ? (y/yes or n/no): " certificate
# 	fi
# }

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

docker_exec() {
	docker-compose exec $1 $2
}

make_dir() {
	mkdir $PWD/www/$domain
}

install_wp() {
	set_domain

	set_nginx

	set_certificate

	wp_cli() {
		docker_exec "backend" "wp core download --path=$domain --locale=ru_RU --allow-root"
		chown -R www-data:www-data $PWD/www/$domain
		chmod -R 775 $PWD/www/$domain
	}

	if [ ! -d "$PWD/www/$domain" ]
	then
		make_dir
		wp_cli
	else
		file_exists $domain wp_cli
	fi

	echo -e "${RED}After finishig of Wordpress configuration you should to change file and directories permissions like a follow line:\n\nchown www-data:www-data -R ./www\nfind ./www -type d -exec chmod 755 {} \; \nfind ./www -type f -exec chmod 644 {} \;${NC}"
}

install_lv() {
	echo "Function doesn't responce, call me later :)"
}

install_git() {
	set_domain

	set_nginx

	set_certificate

	read -p $"Ссылка на репозиторий: " git

	cd $PWD/www/$domain

	git clone $git
}

install_php() {
	echo "Function doesn't responce, call me later :)"
}

PS3=$'\nSelect the project type: '

select number in "Wordpress" "Laravel" "Git проект" "Empty PHP" "Exit"
do
	case $number in
		"Wordpress")
			install_wp
			break
		;;
		"Laravel")
			install_lv
			break
		;;
		"Git project")
			install_git
			break
		;;
    "Empty PHP")
			install_php
			break
		;;
		"Exit")
			exit 0
		;;
		*) echo "Invalid option";;
	esac
done