#!/bin/bash
set -e
DEBUG="false"
CURLOPTS=" -s"
CAPTCHA_METHOD="manual"

CAPTCHA_FAIL=1
LOGIN_UID_EMPTY=2

if [ "$DEBUG" = "true" ]; then
	set -x
	CURLOPTS="$CURLOPTS"
fi
BASEURL=http://$1
USER=$2
PASSWORD=$3
CAPTCHAPATH=.

debug_log () {
	if [ "$DEBUG" = "true" ]; then
		echo "$1" >&2
	fi
}
error_log () {
	echo "$1" >&2
}

get_captcha_text (){
	debug_log "Performing captcha"
	curl $CURLOPTS -o ${CAPTCHAPATH}/hpcaptcha.bmp $BASEURL/vld.bmp?1.40179884898219587
	convert -quiet ${CAPTCHAPATH}/hpcaptcha.bmp ${CAPTCHAPATH}/hpcaptcha.jpg
	case "$CAPTCHA_METHOD" in
			manual)
					open ${CAPTCHAPATH}/hpcaptcha.jpg
					open ${CAPTCHAPATH}/hpcaptcha.bmp
					read manual_entry
					echo "$manual_entry"
					;;
			gocr)
					gocr -i ${CAPTCHAPATH}/hpcaptcha.jpg || (echo "gocr failed" && exit $CAPTCHA_FAIL)
					;;
	esac
	if [ ! "true" = "$DEBUG" ]; then
		true
		#rm ${CAPTCHAPATH}/hpcaptcha.bmp ${CAPTCHAPATH}/hpcaptcha.jpg
	fi
}
get_login_response (){
	debug_log "Perfoming login"
	captcha_text=$(get_captcha_text)
	debug_log "Have captcha text: $captcha_text"
curl $CURLOPTS "$BASEURL/Web/login" -H \
	'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'\
	-H 'Accept-Encoding: gzip, deflate'\
	-H 'Accept-Language: de,en-US;q=0.7,en;q=0.3'\
	-H 'Cache-Control: max-age=0'\
	-H 'Connection: keep-alive'\
	-H 'Cookie: lang=0'\
	-H 'Upgrade-Insecure-Requests: 1'\
	-H 'Content-Type: application/x-www-form-urlencoded'\
	--data 'user_name='$USER'&navigator=Firefox&password='$PASSWORD'&vldcode='$captcha_text'&lang=0'
}

get_login_uid() {
	debug_log "Acquiring login uid"
	login_response_body=$(get_login_response)
	debug_log "login_response_body"
	parsed_uid=$(echo "$login_response_body" |xmllint --xpath "/ROOT/uid/text()" - 2>/dev/null)
	debug_log "got uid: $parsed_uid"
	if [ -z "$parsed_uid" ]; then
			error_log "login uuid empty"
			if [ "true" = "$DEBUG" ]; then
				open $CAPTCHAPATH/hpcaptcha.bmp
			fi
			exit $LOGIN_UID_EMPTY
	fi
	echo "$parsed_uid"
}

# $1 login uid
download_config() {
	curl $CURLOPTS "$BASEURL/wcn/sysmanage/backup_sub"\
	-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'\
	-H 'Accept-Language: de,en-US;q=0.7,en;q=0.3'\
	-H 'Accept-Encoding: gzip, deflate'\
	-H 'Cookie: lang=0'\
	-H 'Connection: keep-alive'\
	-H 'Upgrade-Insecure-Requests: 1'\
	-H 'Cache-Control: max-age=0'\
	-H 'Content-Type: application/x-www-form-urlencoded'\
	--data 'backupcft=Backup&uid='$1'&cfgtype=0'

}

login_uid=""
login_attempts=0
while [ "$login_uid" == "" ] && [ $login_attempts -lt 3 ]; do
	login_uid=$(get_login_uid)
	login_attempts=$(($login_attempts+1))
	echo "Attempted login $login_attempts"
done
if [ "$login_uid" == "" ]; then
	exit $LOGIN_UID_EMPTY
fi

download_config "$login_uid" 
