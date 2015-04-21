
# Check if openssl is avaliable
if ! command_exists "$EXEC_OPENSSL"; then
	echo "ERROR: openssl can't be found [$EXEC_OPENSSL]"
	exit
fi

#Define regex rules
regexKeyComment="^ssh-rsa .+ (.+)$"
regexKeyLength="([0-9]+) bit"

# Get all the key types
KEY_TYPES=`find $KEY_PATH_ROOT/ -mindepth 1 -maxdepth 1 -type d -printf "%f\n"`

echo "Type	Length		Connection String	Flags	Comment"

# Loop through all the key types
for keytype in $KEY_TYPES; do

	# Set the path to this type of key
	keytypepath="$KEY_PATH_ROOT/$keytype"

	# Find all the domains with a key of this type
	KEY_DOMAINS=`find $keytypepath/ -mindepth 1 -maxdepth 1 -type d -printf "%f\n"`

	# Loop through each domain
	for keydomain in $KEY_DOMAINS; do

		# Set the path to the key files for this domain
		keydomainpath="$keytypepath/$keydomain"

		# Get all the keys for this domain
		KEY_USERS=`find $keydomainpath/ -mindepth 1 -maxdepth 1 -type f ! -name \*.pub -printf "%f\n"`

		# Loop through each key file we could find
		for keyuser in $KEY_USERS; do

			# Reset
			keylength="????"
			keyflags=""
			keycomment=""

			# Check if the public key can be found
			if [ -f "$keydomainpath/$keyuser.pub" ]; then

				# Get the comment from the key
				[[ `cat "$keydomainpath/$keyuser.pub"` =~ $regexKeyComment ]]
				keycomment="${BASH_REMATCH[1]}"

				keyflags="$keyflags[PUB] "
			else
				keyflags="$keyflags[$COLOUR_RED""NO PUB$COLOUR_RST] "
			fi

			# Get Key length
			[[ `$EXEC_OPENSSL $keytype -in "$keydomainpath/$keyuser" -text -noout` =~ $regexKeyLength ]]
			keylength="${BASH_REMATCH[1]}"

			# Check if the key is of a proper length
			if [[ $keylength -lt "$KEY_MIN_LENGH" ]]; then
				keylength="$COLOUR_RED_BAK$keylength bit$COLOUR_RST"
			else
				keylength="$COLOUR_YEL$keylength bit$COLOUR_RST"
			fi

			# Show the information
			echo -e "${keytype^^}	$keylength   	$COLOUR_CYN$keyuser$COLOUR_RST@$COLOUR_PUR$keydomain$COLOUR_RST	$keyflags	$keycomment"
		done
	done
done

