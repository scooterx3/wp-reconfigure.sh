#!/bin/bash
echo "dude welcome"
OPTIND=1

wpcfg() {
	# I want verbosity OFF and auto mode by default (even if no arguments are specified)
	verbose=false
	mode='auto'

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
	echo "$dbhost_old $dbname_old $dbpass_old $dbuser_old"

	# process at this point and create dbhost_new, dbname_new, etc. 


	dbhost_new='localhostttttttttt'
	dbname_new='new_db'
	dbpass_new='somep@ssw0rd'
	dbuser_new='new_user'


	if [[ $mode == 'manual' ]]; then
		if [[ $verbose == 'true' ]]; then echo "Manual mode"; fi
		read -p "db user pass [host]" dbname_new dbuser_new dbpass_new dbhost_new
		if [[ $verbose == 'true' ]]; then echo -e "You entered: \nDB: $dbname_new \nUser: $dbuser_new \nPass: $dbpass_new \nHost: $dbhost_new"; fi

		# If the 4th argument isn't passed (dbhost_new), just set it to 'localhost'
		if [[ -z $dbhost_new ]]; then
			if [[ $verbose == 'true' ]]; then echo "dbhost_new was empty, setting as 'localhost'"; fi
			dbhost_new='localhost'
		fi

	elif [[ $mode == 'current' ]]; then
		if [[ $verbose == 'true' ]]; then echo "Current mode"; fi
	elif [[ $mode == 'help' ]]; then
		if [[ $verbose == 'true' ]]; then echo "Help mode"; fi
	else
		if [[ $verbose == 'true' ]]; then echo "Auto mode"; fi

	fi


	if [[ -z $dbpass_new ]]; then
		echo "no dbpass_new"
		wpcfg_fail		
	else
		# The magic happens (replacing things)
		sed -e "s|DB_NAME\(['\"]\),\s*\?\(['\"]\)${dbname_old}|DB_NAME\1, \2${dbname_new}|;
		s|DB_USER\(['\"]\),\s*\?\(['\"]\)${dbuser_old}|DB_USER\1, \2${dbuser_new}|;
		s|DB_PASSWORD\(['\"]\),\s*\?\(['\"]\)${dbpass_old}|DB_PASSWORD\1, \2${dbpass_new}|;
		s|DB_HOST\(['\"]\),\s*\?\(['\"]\)${dbhost_old}|DB_HOST\1, \2${dbhost_new}|" wp-config_whatevahbackup_.php > newfile.txt
	fi

# DB_USER\1, \1${dbuser_new}
	# for getting only those lines that don't start with comments...  /^\//! 
	# for pw, 8 almost guaranteed
	# less than that, add a few chars. 
	# "s|DB_NAME['"],\s?\(['"]\)${dbname_old}|DB_NAME\1, \1${dbname_new}"





}
echo "broken3"

wpcfg_fail() {

	echo "failed"
}





