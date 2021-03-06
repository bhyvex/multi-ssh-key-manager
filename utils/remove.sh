
# Declare an array of removal programs
declare -A removalCommands
removalCommands['rm']="rm -f"
removalCommands['shred']="shred -zu"
removalCommands['shred100']="shred -zun 100"

# Get just the command
regexArgRemovalProgramExec='(/?[^ ]+)'
[[ ${removalCommands[$KEY_REMOVAL_PROG]} =~ $regexArgRemovalProgramExec ]]
removalProgramExec="${BASH_REMATCH[1]}"

# Check the requested removal command is avaliable
if ! command_exists $removalProgramExec; then
	echo "$removalProgramExec NOT FOUND"
	#Use RM as a safe default
	KEY_REMOVAL_PROG="rm"
fi

# Get the removal command with flags to run
removalCommand="${removalCommands[$KEY_REMOVAL_PROG]}"

# Tell the user which command were using to remove the keys
echo "Removing keys using '$removalCommand'"

# Check the private key exists
if [ -f "$KEY_PATH_PRIV" ]; then
	# Remove the keys
	$removalCommand "$KEY_PATH_PRIV"

	# Tell the user the private key has been removed
	echo "$KEY_USER@$KEY_HOSTNAME: Removed the private key"
else
	# Tell the user the private key cant be removed
	echo "$KEY_USER@$KEY_HOSTNAME: No private key found"
fi

# Check the public key exists
if [ -f "$KEY_PATH_PUB" ]; then
	# Remove the key
	$removalCommand "$KEY_PATH_PUB"

	# Tell the user the private key has been removed
	echo "$KEY_USER@$KEY_HOSTNAME: Removed the public key"
else
	# Tell the user the private key cant be removed
	echo "$KEY_USER@$KEY_HOSTNAME: No public key found"
fi

# Cleanup, Remove any empty key directories
find "$KEY_PATH_ROOT/$KEY_TYPE/" -type d -empty -delete
