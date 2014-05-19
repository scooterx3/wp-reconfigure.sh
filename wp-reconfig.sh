#!/bin/bash
echo "dude welcome"


wpcfg() {

	OPTIND=1
	backupfile='wp-config_original_.php'
	
	if [[ $1 == '-h' ]]; then
		echo "Now vomiting helpful information..."
		return
	fi

	# I want verbosity OFF and auto mode by default (even if no arguments are specified)
	

	unset dbhost_new dbname_new dbpass_new dbuser_new verbose

	while getopts ":amcvh" opt; do
		case $opt in
			a)
				mode='auto' ;;
			m)
				mode='manual' ;;
			c) 
				mode='current' ;;
			v)
				verbose='true' ;;
		esac
	done
	shift $((OPTIND-1))
	OPTIND=1

	if [[ ! -f wp-config.php ]]; then
		
		echo "No wp-config.php!"
		return
	fi

	cp -n wp-config.php $backupfile
	read -r dbhost_old dbname_old dbpass_old dbuser_old <<< $( egrep "^[^/].*['\"]DB_(NAME|USER|PASSWORD|HOST[^_])" wp-config.php | sort -d | sed "s/.*[\"']\(.*\)[\"'].*;.*/\1/" )

	if [[ $mode == 'current' ]]; then
#CURRENT
		echo "$dbname_old $dbuser_old $dbpass_old"
		return
	fi

	random_string=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
	cpuser=`whoami`

	if [[ $mode == 'manual' ]]; then
#MANUAL
		if [[ $verbose == 'true' ]]; then echo -e "\n[MANUAL]"; fi
		#echo -e "db user [pass] [host]"
		echo -e "db user [pass] [host]"
		read -p "" dbname_new dbuser_new dbpass_new dbhost_new
		# if [[ $verbose == 'true' ]]; then echo -e "You entered: \nDB: $dbname_new \nUser: $dbuser_new \nPass: $dbpass_new \nHost: $dbhost_new"; fi

		# if no dbpass was entered, set it to a random string
		if [[ -z $dbpass_new ]]; then
			if [[ $verbose == 'true' ]]; then echo "dbpass_new was empty, assigning a random value..."; fi
			dbpass_new=$random_string
		fi

		# If the 4th argument isn't passed (dbhost_new), just set it to 'localhost'
		if [[ -z $dbhost_new ]]; then
			if [[ $verbose == 'true' ]]; then echo "dbhost_new was empty, setting as 'localhost'..."; fi
			dbhost_new='localhost'
		fi

	else
#AUTO
		if [[ $verbose == 'true' ]]; then echo -e "\n[AUTO]"; fi

		leftside=$cpuser"_"
		leftside_length=${#leftside}

	#DBNAME
		dbname_rightside=${dbname_old#$leftside}
		dbname_new=$leftside$dbname_rightside

	#USERNAME	
		
		dbuser_rightside=${dbuser_old#$leftside}
		if (( ${#dbuser_rightside} > 16-$leftside_length )); then
			echo 'true'
			dbuser_new=$leftside${dbuser_rightside:$leftside_length-16}
		else
			echo 'false'
			dbuser_new=$leftside$dbuser_rightside
		fi

	#PASSWORD
		# pass is different, just keep it unless it's shorter than 5. If so, add a random 5 to the end of the string. 
		if (( ${#dbpass_old} < 5 )); then 
			if [[ $verbose == 'true' ]]; then echo "dbpass_old < 5 chars, adding random string: '$random_string'"; fi 
			
			dbpass_new=$dbpass_old$random_string #random_string defined at the top, I use it in more than 1 place
		else 
			if [[ $verbose == 'true' ]]; then echo "dbpass_old >= 5 chars, keeping old password"; fi 
			dbpass_new=$dbpass_old
		fi
	#HOST
		# host will always be 'localhost'
		dbhost_new='localhost'
	fi

	if [[ -z $dbuser_new ]]; then
		if [[ $verbose == 'true' ]]; then echo "dbuser_new was empty, exiting"; fi
	
	else
		# clean up right side for sed's use
		for i in dbname_new dbuser_new dbpass_new dbhost_new; do
			declare safe_$i=$(printf '%s' "${!i}" | sed -e 's|\\|\\\\|g; s|&|\\\&|g')
		done

		sed -i -e "s|DB_NAME\(['\"]\),\s*\(['\"]\).*\?\2|DB_NAME\1, \2$safe_dbname_new\2|
		s|DB_USER\(['\"]\),\s*\(['\"]\).*\?\2|DB_USER\1, \2$safe_dbuser_new\2|
		s|DB_PASSWORD\(['\"]\),\s*\(['\"]\).*\?\2|DB_PASSWORD\1, \2$safe_dbpass_new\2|
		s|DB_HOST\(['\"]\),\s*\(['\"]\).*\?\2|DB_HOST\1, \2$safe_dbhost_new\2|" wp-config.php

		# spit it out!
		if [[ $dbhost_new == 'localhost' ]]; then dbhost_new=''; echo "omitting 'localhost' from output of new credentials..."; fi
		echo -e "\nOLD:\n   $dbname_old $dbuser_old $dbpass_old $dbhost_old"
		echo -e "\nNEW:\n   $dbname_new $dbuser_new $dbpass_new $dbhost_new"
		echo -e "\n"

	fi
	

}





