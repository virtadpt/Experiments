#!/bin/bash

# www.example.com

echo "Renewing the Let's Encrypt SSL cert..."
python /home/letsencrypt/acme_tiny.py --account www/account.key \
    --csr www/domain.csr --acme-dir /srv/www/challenges > www/signed.crt

echo "Getting Let's Encrypt cross-signed PEM file."
wget -O - https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem \
	> www/intermediate.pem

echo "Concatenating cross-signed PEM with our SSL certificate."
cat www/signed.crt www/intermediate.pem > www/chained.pem

echo "Testing configuration."
sudo /usr/sbin/nginx -t
if [ $? -gt 0 ]; then
    echo "WARNING: Bad configuration detected."
    exit 1
fi

echo "Restarting Nginx so changes will take effect."
sudo /usr/sbin/service nginx restart

exit 0

