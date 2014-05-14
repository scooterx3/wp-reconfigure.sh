#!/bin/bash
echo "dude welcome"
OPTIND=1

wpcfg() {
	# I want verbosity OFF and auto mode by default (even if no arguments are specified)
	verbose=false
	mode='auto'
	random_string=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
	cpuser=`whoami`

	dbhost_new=''
	dbname_new=''
	dbpass_new=''
	dbuser_new=''

	while getopts ":amcvh" opt; do
		case $opt in
			a)
				mode='auto';
				;;
			m)
				mode='manual';
				;;
			c) 
				mode='current';
				;;
			v)
				verbose='true';
				;;
			h)
				mode='help';
				;;
		esac
	done
	shift $((OPTIND-1))
	OPTIND=1

	if [[ $verbose == 'true' ]]; then echo "Mode: $mode"; fi
	
	#cp wp-config.php wp-config_whatevahbackup_.php
	read -r dbhost_old dbname_old dbpass_old dbuser_old <<< $( egrep "^[^/].*['\"]DB_(NAME|USER|PASSWORD|HOST[^_])" wp-config_whatevahbackup_.php | sort -d | sed "s/.*[\"']\(.*\)[\"'].*;.*/\1/" )
	echo "Old values: $dbhost_old $dbname_old $dbpass_old $dbuser_old"

	#new creds for testing
	# dbhost_new='localhostttttttttt'
	# dbname_new='new_db'
	# dbpass_new='somep@ssw0rd'
	# dbuser_new='new_user'
	#new creds for testing


	if [[ $mode == 'manual' ]]; then
		if [[ $verbose == 'true' ]]; then echo "Manual mode running"; fi
		read -p "db user [pass] [host]" dbname_new dbuser_new dbpass_new dbhost_new
		if [[ $verbose == 'true' ]]; then echo -e "You entered: \nDB: $dbname_new \nUser: $dbuser_new \nPass: $dbpass_new \nHost: $dbhost_new"; fi

		# if no dbpass was entered, set it to a random string
		if [[ -z $dbpass_new ]]; then
			if [[ $verbose == 'true' ]]; then echo "dbpass_new was empty, assigning a random value"; fi
			dbpass_new=$random_string
		fi

		# If the 4th argument isn't passed (dbhost_new), just set it to 'localhost'
		if [[ -z $dbhost_new ]]; then
			if [[ $verbose == 'true' ]]; then echo "dbhost_new was empty, setting as 'localhost'"; fi
			dbhost_new='localhost'
		fi

	elif [[ $mode == 'current' ]]; then
		[[ $verbose == 'true' ]] && echo "Current mode running"
	elif [[ $mode == 'help' ]]; then
		if [[ $verbose == 'true' ]]; then echo "Help mode running"; fi
	else
#AUTO
		if [[ $verbose == 'true' ]]; then echo "Auto mode running"; fi
		# this is auto mode

		# fix dbname
		# if cPanel user is the same, keep it otherwise prefix whatever is there with cpuser_
		if [[ $dbname_old == $cpuser"_*" ]]; then
			dbname_new=$dbname_old
		else
			dbname_new=$cpuser"_"$dbname_old
		fi

		# fix username
		# if cPanel user is the same, keep it otherwise prefix whatever is there with cpuser_
		if [[ $dbuser_old == $cpuser"_*" ]]; then
			dbuser_new=$dbuser_old
			echo "true"
		else
			dbuser_new=$cpuser"_"$dbuser_old
			echo "false"
			echo "$cpuser"
		fi

		# making sure new dbuser isn't too long
		if [[ ${#dbuser_new} > 16 ]]; then
			if [[ verbose == 'true' ]]; then echo "dbuser_new too long, truncating"; fi
			dbuser_new=${dbuser_new:0:16}
		fi


		# pass is different, just keep it unless it's shorter than 5. If so, add a random 5 to the end of the string. 
		dbpass_old_size=${#dbpass_old}
		if [[ $dbpass_old_size < 5 ]]; then 
			if [[ $verbose == 'true' ]]; then echo "dbpass_old < 5 chars, adding random string: '$random_string'"; fi 
			
			dbpass_new=$dbpass_old$random_string #random_string defined at the top, I use it in more than 1 place
			echo $dbpass_new
		else 
			if [[ $verbose == 'true' ]]; then echo "dbpass_old >= 5 chars, keeping old password"; fi 
			dbpass_new=$dbpass_old
		fi
		# host will always be 'localhost'
		dbhost_new='localhost'

	fi


	if [[ -z $dbuser_new ]]; then
		echo "dbuser_new was empty, exiting"
	
	else
		# The magic happens (replacing things)
		sed -e "s|DB_NAME\(['\"]\),\s*\?\(['\"]\)${dbname_old}|DB_NAME\1, \2${dbname_new}|
		s|DB_USER\(['\"]\),\s*\?\(['\"]\)${dbuser_old}|DB_USER\1, \2${dbuser_new}|
		s|DB_PASSWORD\(['\"]\),\s*\?\(['\"]\)${dbpass_old}|DB_PASSWORD\1, \2${dbpass_new}|
		s|DB_HOST\(['\"]\),\s*\?\(['\"]\)${dbhost_old}|DB_HOST\1, \2${dbhost_new}|" wp-config_whatevahbackup_.php > newfile.txt
	fi

# DB_USER\1, \1${dbuser_new}
	# for getting only those lines that don't start with comments...  /^\//! 
	# for pw, 8 almost guaranteed
	# less than that, add a few chars. 
	# "s|DB_NAME['"],\s?\(['"]\)${dbname_old}|DB_NAME\1, \1${dbname_new}"





}





