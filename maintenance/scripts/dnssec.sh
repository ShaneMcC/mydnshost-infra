#!/bin/sh

mkdir -p /bind/keys
chmod a+w /bind/

ls -1 /bind/zones/ | while read ZONE; do
	EXT=${ZONE##*.}
	ZONE=${ZONE%.*}
	if [ "${EXT}" = "db" -a -e "/bind/zones/${ZONE}.db" ]; then
		KEYS=`ls '/bind/keys/K'"${ZONE}"*'.key' 2>/dev/null`

		if [ "${KEYS}" = "" ]; then
			echo "Generating Keys for: ${ZONE}"
			dnssec-keygen -r /dev/urandom -a RSASHA256 -b 2048 -K /bind/keys/ -f KSK ${ZONE}
			dnssec-keygen -r /dev/urandom -a RSASHA256 -b 1024 -K /bind/keys/ ${ZONE}

			rndc loadkeys ${ZONE}
			rndc sign ${ZONE}
		fi;

		if [ ! -e "/bind/keys/${ZONE}.dskey" ]; then
			KSK=`grep -l key-signing '/bind/keys/K'"${ZONE}"*'.key'`

			if [ "${KSK}" != "" ]; then
				dnssec-dsfromkey "${KSK}" > "/bind/keys/${ZONE}.dskey"
			fi;
		fi;
	fi;
done;


