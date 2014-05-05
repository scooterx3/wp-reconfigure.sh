wp-reconfigure.sh
=================


Wanting to rebuild my wp-reconfigure but in bash so that I can more easily throw options/flags at it, etc. 

### Desired options:

- [ ] --auto (default)
 -   Default option (no need to specify)
 -   Spits out the single DB line
 -   reconfigures the wp-config.php file
 -   Spits out notifications
- [ ] --manual
 -   Allows one to specify a DB line
 -   Spits out notifications   
- [ ] --current
 -   Spits out current DB line
 -   Spits out notifications
- [ ] -v, --verbose
 -   Just what it says
 

### Desired features:
- [ ] Ignore comments in wp-config.php
- [ ] Keep old password (but if too short, just add some characters)
- [ ] Keep old user
- [ ] Notify if any caching lines are present in wp-config.php
- [ ] Notify if any WPMU lines are present
- [ ] Spit out the site URL is, if those lines are present in wp-config.php
- [ ] Notify what the 'content folder' is (or if it's just not default)
- [ ] Notify if debug mode is on?
