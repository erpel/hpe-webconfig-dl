#!/bin/sh
set +x
BASEURL=http://$1
USER=$2
PASSWORD=$3


get_captcha_text (){
	curl -o /tmp/hpcaptcha.bmp $BASEURL/vld.bmp?1.40179884898219587
	convert /tmp/hpcaptcha.bmp /tmp/hpcaptcha.jpg
	gocr -i /tmp/hpcaptcha.jpg
	rm /tmp/hpcaptcha.bmp /tmp/hpcaptcha.jpg
}
get_login_response (){
	captcha_text=$(get_captcha_text)
curl "$BASEURL/Web/login" -H \
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
	login_response_body=$(get_login_response)
	echo "$login_response_body" |xmllint --xpath "/ROOT/uid/text()" - 2>/dev/null
}

# $1 login uid
download_config() {
	curl "$BASEURL/wcn/sysmanage/backup_sub"\
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
done
if [ "$login_uid" == "" ]; then
	exit 1
fi

download_config "$login_uid" 
