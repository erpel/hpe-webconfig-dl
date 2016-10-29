# HPE webconfig downloader

This is the first attempt at downloading config from HPE "smart managed" ethernet switches.
Confirmed working with 1920 series.

## Prerequsites

* sh shell
* gocr OCR tool http://jocr.sourceforge.net
* xmllint http://www.xmlsoft.org/

## Usage

Give the hostname/ip address as first argument, followed by username and password.
The config is output to stdout. 3 attempts are made to log in and solve the captcha, if
this does not succeed, exits with return value of 1.

	sh hpconf.sh <HOST> <USER> <PASSWORD>

### Example

	sh hpconf.sh 192.168.1.1 admin password
