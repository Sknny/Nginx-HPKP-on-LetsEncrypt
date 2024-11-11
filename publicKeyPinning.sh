#!/bin/bash
 
# By Igor Slavin.

letsEncryptDirectory="/etc/letsencrypt/live/example.com"
nginxHostConfig="/etc/nginx/sites-enabled/example.com.conf"


### End of configuration

show_help () {
echo "This script will fetch hash from the Letsencrypt Certificate and and put it into your Apache2 configuration.
Read more about on: https://gist.github.com/GAS85/a668b941f84c621a15ff581ae968e4cb
Syntax is publicKeyPinning.sh -h?d --dry-run
        -h, or ?        for this help
        -d      will only generate output without writting to the config
        --dry-run       is the same as -d
By Igor Slavin."
}

set -e

for i in "$@"; do
        case $i in
                -h|\?)
                        show_help
                        exit 0
                ;;
                -d|--dry-run)
                dry=true
        ;;
        esac
done

# Check if you are root user
[[ $(id -u) -eq 0 ]] || { echo >&2 "You should be root to run this script."; exit 1; }

# Check if file exist
[[ -e $letsEncryptDirectory/cert.pem ]] || { echo >&2 "File $letsEncryptDirectory/cert.pem does't exist."; exit 1; }

# Check if file is writtable by Process
[[ -e $nginxHostConfig ]] || { echo >&2 "File $nginxHostConfig does't exist."; exit 1; }

# Check if file is writtable by Process
[[ -w $nginxHostConfig ]] || { echo >&2 "File $nginxHostConfig is not writable by process."; exit 1; }

# Calculating new hash of the file
hash1=$(cat $letsEncryptDirectory/cert.pem | openssl x509 -pubkey | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64)

# Fetching current hash from the config
hash1_in_config=$(grep "add_header Public-Key-Pins" $nginxHostConfig | awk -F'["]' '{ print $3 }' | rev | cut -c 2- | rev)

if [ "$dry" != "true" ]; then

        if [ "$hash1" != "$hash1_in_config" ]; then

                sed -i -e "s#$hash1_in_config#$hash1#g" $nginxHostConfig

                # Check nginx Config and reload the server
                nginx -t
                service nginx restart > null
        fi

else

        # Collect Lets Encrypt hashes
        hash2=$(curl -s https://letsencrypt.org/certs/lets-encrypt-x4-cross-signed.pem | openssl x509 -pubkey | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base6>
        hash3=$(curl -s https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem | openssl x509 -pubkey | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base6>
        hash4=$(curl -s https://letsencrypt.org/certs/isrgrootx1.pem | openssl x509 -pubkey | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64)

        echo "Current Hash in Config"
        echo "  "$hash1_in_config
        echo "Hash from the certificate"
        echo "  "$hash1
        echo
        echo "You porbably have to added following root Certificates of LetsEncrypt hashes in your config file if they are not presented there"
        echo "X4        "$hash2

fi

exit 0