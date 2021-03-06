#!/bin/sh

#Set Molopa
if env | grep -q ^WITH_MOLOPA=; then
	if [ $WITH_MOLOPA -eq "True" ]; then
		echo "Activating Molopa."
		(crontab -l 2>/dev/null; echo "* * * * * molopa -l /var/log/modsecurity/audit.log -s /var/log/modsecurity/data") | crontab -
	else
		echo "Molopa deactivated."
	fi
else
	echo "Molopa deactivated."
fi
#Use external bad.html
if env | grep -q ^WITH_BLOCK_PAGE=; then
	echo "Using $WITH_BLOCK_PAGE as blockpage."
	wget --output-document="/usr/local/nginx/html/bad.html" $WITH_BLOCK_PAGE
fi
#Fetch configuration
if env | grep -q ^REMOTE_CONFIG=; then
	echo "Fetching configuration..."
	fetch_modsecurity_configuration $REMOTE_CONFIG
fi
if env | grep -q ^REMOTE_CONFIG=; then
	wget --output-document="/usr/local/nginx/html/bad.html" $WITH_BLOCK_PAGE
fi
echo "Generating NGINX configuration..."
nginxconf
echo "Generating ModSecurity configuration..."
if env | grep -q ^MODSECURITY_ENGINE=; then
	if [ $MODSECURITY_ENGINE -eq "Off" ]; then
		sed -i "/^SecRuleEngine /s/ .*/ DetectionOnly/" /etc/modsecurity/modsecurity.conf
	else
		sed -i "/^SecRuleEngine /s/ .*/ On/" /etc/modsecurity/modsecurity.conf
	fi
else
	sed -i "/^SecRuleEngine /s/ .*/ On/" /etc/modsecurity/modsecurity.conf
fi
if env | grep -q ^MODSECURITY_PARSE_REQUEST_BODY=; then
	if [ $MODSECURITY_PARSE_REQUEST_BODY -eq "Off" ]; then
		sed -i "/^SecRequestBodyAccess /s/ .*/ Off/" /etc/modsecurity/modsecurity.conf
	else
		sed -i "/^SecRequestBodyAccess /s/ .*/ On/" /etc/modsecurity/modsecurity.conf
	fi
else
	sed -i "/^SecRequestBodyAccess /s/ .*/ On/" /etc/modsecurity/modsecurity.conf
fi
if env | grep -q ^MODSECURITY_PARSE_RESPONSE_BODY=; then
	if [ $MODSECURITY_PARSE_RESPONSE_BODY -eq "Off" ]; then
		sed -i "/^SecResponseBodyAccess /s/ .*/ Off/" /etc/modsecurity/modsecurity.conf
	else
		sed -i "/^SecResponseBodyAccess /s/ .*/ On/" /etc/modsecurity/modsecurity.conf
	fi
else
	sed -i "/^SecResponseBodyAccess /s/ .*/ On/" /etc/modsecurity/modsecurity.conf
fi
sed -i "/^#SecUploadDir /s/^#*//" /etc/modsecurity/modsecurity.conf
if env | grep -q ^MODSECURITY_DEBUG=; then
	if [ "$MODSECURITY_DEBUG" == "On" ]; then
		echo "Enabling ModSecurity debug log."
		sed -i "/^#SecDebugLog /s/^#*//" /etc/modsecurity/modsecurity.conf
		sed -i "/^#SecDebugLogLevel /s/^#*//" /etc/modsecurity/modsecurity.conf
	fi
fi
echo "Running NGINX..."
#Run NGINX
/usr/local/nginx/sbin/nginx