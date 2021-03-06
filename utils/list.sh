
# Check if openssl is avaliable
command_exists_exit "$EXEC_OPENSSL"

# Define an array of users to make sure we can separate pub and private keys
declare -A userHostArray

#Define regex rules
regexKeyComment="^ssh-rsa .+ (.+)$"
regexKeyLength="([0-9]+) bit"
regexKeyFile='^([^\.]+)(.pub)?$'

# Check if there are any keys
KEY_COUNT=`find $KEY_PATH_ROOT/**/* -follow -type f -printf "%f\n" | wc -l`

if [ $KEY_COUNT = 0 ]; then
	echo "No keys could be found"
	exit
fi

# Get all the key types
KEY_TYPES=`find $KEY_PATH_ROOT/ -follow -mindepth 1 -maxdepth 1 -type d -printf "%f\n"`

# Output the table headers
echo -e "Type\033[10GLength\033[24GUser\033[40GServer\033[63GFlags\033[81GComment"

# Loop through all the key types
for keyType in $KEY_TYPES; do

	# Set the path to this type of key
	keyTypePath="$KEY_PATH_ROOT/$keyType"

	# Find all the hostnames with a key of this type
	KEY_HOSTNAMES=`find $keyTypePath/ -follow -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort`

	# Loop through each hostname
	for keyHostname in $KEY_HOSTNAMES; do

		# Set the path to the key files for this hostname
		keyHostnamePath="$keyTypePath/$keyHostname"

		# Get all the keys for this hostname
		KEY_USERS=`find $keyHostnamePath/ -follow -mindepth 1 -maxdepth 1 -type f -printf "%f\n" | sort`

		# Loop through each key file we could finds
		for keyFile in $KEY_USERS; do

			# Get the user name from this key
			[[ $keyFile =~ $regexKeyFile ]]
			keyUsername="${BASH_REMATCH[1]}"

			# Check if we have already displayed the key for this user
			if [ "${userHostArray["$keyHostname$keyUsername"]}" = true ]; then
				continue
			fi

			# Add this user to the array of users weve already proccessed
			userHostArray["$keyHostname$keyUsername"]=true

			# Set the paths for the pub and private keys
			keyPathPub="$keyHostnamePath/$keyUsername.pub"
			keyPathPriv="$keyHostnamePath/$keyUsername"

			# Resets
			keyLength="????"
			keyFlags=""
			keyComment=""

			# Check if the public key can be found
			if [ -f "$keyPathPub" ]; then

				# Get the comment from the key
				[[ `cat "$keyPathPub"` =~ $regexKeyComment ]]
				keyComment="${BASH_REMATCH[1]}"

				keyFlags="$keyFlags[$COLOUR_GRN""PUB$COLOUR_RST] "
			else
				keyFlags="$keyFlags[$COLOUR_RED""NO PUB$COLOUR_RST] "
			fi

			# Check if the private key can be found
			if [ -f "$keyPathPriv" ]; then

				# Get Key length
				[[ `$EXEC_OPENSSL $keyType -in "$keyPathPriv" -text -noout` =~ $regexKeyLength ]]
				keyLength="${BASH_REMATCH[1]}"

				# Check if the key is of a proper length
				if [[ $keyLength -lt "$KEY_MIN_LENGH" ]] || [[ $keyLength -eq "$KEY_MIN_LENGH" ]]; then
					keyLength="$COLOUR_RED_BAK$keyLength bit$COLOUR_RST"
				else
					keyLength="$COLOUR_YEL$keyLength bit$COLOUR_RST"
				fi

				keyFlags="$keyFlags[$COLOUR_GRN""PRV$COLOUR_RST] "
			else
				keyFlags="$keyFlags[$COLOUR_RED""NO PRV$COLOUR_RST] "
			fi

			# Check if the key is a symlink
			if [ -L "$keyPathPub" ] || [ -L "$keyHostnamePath" ]; then
				keyFlags="$keyFlags[$COLOUR_YEL""SYM$COLOUR_RST] "
			fi

			# Check if we should show the keys path
			if [ $KEY_PATH_SHOW = true ]; then
				keyPathComment=" => $keyPathPriv"
			fi

			# Show the information
			echo -e "${keyType^^}\033[10G$keyLength\033[24G$COLOUR_CYN$keyUsername$COLOUR_RST\033[40G$COLOUR_PUR$keyHostname$COLOUR_RST\033[63G$keyFlags\033[81G$COLOUR_GRY$keyComment$COLOUR_RST $keyPathComment"
		done
	done
done

