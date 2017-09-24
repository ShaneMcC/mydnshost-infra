#!/bin/sh

mkdir -p /bind/keys
chmod a+w /bind/

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

DNSSEC_KEYGEN=`which dnssec-keygen`
RNDC=`which rndc`

if [ "${DNSSEC_KEYGEN}" = "" -o "${RNDC}" = "" ]; then
	echo "Error: Unable to locate dnssec-keygen or rndc."
	exit 1;
fi;

ls -1 /bind/zones/ | while read ZONE; do
	EXT=${ZONE##*.}
	ZONE=${ZONE%.*}
	if [ "${EXT}" = "db" -a -e "/bind/zones/${ZONE}.db" ]; then
		KEYS=`ls '/bind/keys/K'"${ZONE}"*'.key' 2>/dev/null`

		if [ "${KEYS}" = "" ]; then
			echo "Generating Keys for: ${ZONE}"
			${DNSSEC_KEYGEN} -r /dev/urandom -a RSASHA256 -b 2048 -K /bind/keys/ -f KSK ${ZONE}
			${DNSSEC_KEYGEN} -r /dev/urandom -a RSASHA256 -b 1024 -K /bind/keys/ ${ZONE}

			${RNDC} loadkeys ${ZONE}
			${RNDC} sign ${ZONE}
		fi;

		if [ ! -e "/bind/keys/${ZONE}.dskey" ]; then
			KSK=`grep -l key-signing '/bind/keys/K'"${ZONE}"*'.key'`

			if [ "${KSK}" != "" ]; then
				dnssec-dsfromkey "${KSK}" > "/bind/keys/${ZONE}.dskey"
			fi;
		fi;
	fi;
done;


