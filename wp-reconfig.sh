#!/bin/bash
echo "dude welcome"
OPTIND=1
backupfile='wp-config_original_.php'

wpcfg() {


	if [[ $1 == '-h' ]]; then
		echo "Now vomiting helpful information..."
		return
	fi

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
		esac
	done
	shift $((OPTIND-1))
	OPTIND=1

	
	if [[ -f wp-config.php ]]; then
		cp -n wp-config.php $backupfile
	else
		echo "No wp-config.php!"
		return
	fi

	#cp wp-config.php wp-config_whatevahbackup_.php
	read -r dbhost_old dbname_old dbpass_old dbuser_old <<< $( egrep "^[^/].*['\"]DB_(NAME|USER|PASSWORD|HOST[^_])" wp-config.php | sort -d | sed "s/.*[\"']\(.*\)[\"'].*;.*/\1/" )

	if [[ $mode == 'manual' ]]; then
#MANUAL
		if [[ $verbose == 'true' ]]; then echo -e "\n[MANUAL]"; fi
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
#CURRENT
		verbose='false';
		dbhost_new=''
		dbname_new=''
		dbpass_new=''
		dbuser_new=''
		echo "$dbname_old $dbuser_old $dbpass_old"

	else
#AUTO
		if [[ $verbose == 'true' ]]; then echo -e "\n[AUTO]"; fi
		# this is auto mode

		# fix dbname
		# if cPanel user is the same, keep it otherwise prefix whatever is there with cpuser_
		if [[ $dbname_old == $cpuser"_"* ]]; then
			if [[ $verbose == 'true' ]]; then echo "cPanel user identical, keeping it for db user"; fi
			dbname_new=$dbname_old
		else
			dbname_new=$cpuser"_"$dbname_old
		fi

		# fix username
		# if cPanel user is the same, keep it otherwise prefix whatever is there with cpuser_
		if [[ $dbuser_old == $cpuser"_"* ]]; then
			if [[ $verbose == 'true' ]]; then echo "cPanel user identical, keeping it for db user"; fi
			dbuser_new=$dbuser_old
		else
			dbuser_new=$cpuser"_"$dbuser_old
		fi

		# making sure new dbuser isn't too long
		if (( ${#dbuser_new} > 16 )); then
			if [[ $verbose == 'true' ]]; then echo "dbuser_new too long, truncating"; fi
			dbuser_new=${dbuser_new:0:16}
		fi


		# pass is different, just keep it unless it's shorter than 5. If so, add a random 5 to the end of the string. 
		if (( ${#dbpass_old} < 5 )); then 
			if [[ $verbose == 'true' ]]; then echo "dbpass_old < 5 chars, adding random string: '$random_string'"; fi 
			
			dbpass_new=$dbpass_old$random_string #random_string defined at the top, I use it in more than 1 place
		else 
			if [[ $verbose == 'true' ]]; then echo "dbpass_old >= 5 chars, keeping old password"; fi 
			dbpass_new=$dbpass_old
		fi
		# host will always be 'localhost'
		dbhost_new='localhost'
		

	fi

	
	if [[ -z $dbuser_new ]]; then
		if [[ $verbose == 'true' ]]; then echo "dbuser_new was empty, exiting"; fi
	
	else
		# The magic happens (replacing things)
		sed -i -e "s|DB_NAME\(['\"]\),\s*\?\(['\"]\)${dbname_old}|DB_NAME\1, \2${dbname_new}|
		s|DB_USER\(['\"]\),\s*\?\(['\"]\)${dbuser_old}|DB_USER\1, \2${dbuser_new}|
		s|DB_PASSWORD\(['\"]\),\s*\?\(['\"]\)${dbpass_old}|DB_PASSWORD\1, \2${dbpass_new}|
		s|DB_HOST\(['\"]\),\s*\?\(['\"]\)${dbhost_old}|DB_HOST\1, \2${dbhost_new}|" wp-config.php
		echo -e "\nOLD:\n   $dbname_old $dbuser_old $dbpass_old $dbhost_old"
		echo -e "\nNEW:\n   $dbname_new $dbuser_new $dbpass_new $dbhost_new"
		echo -e "\n"
		grep -i db wp-config.php
	fi
	

}





