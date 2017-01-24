#!/bin/bash


echo "***************************************************************************"
echo "Welcome to the installer for TheBriarPatch to be used with the raspberry PI"
echo "***************************************************************************"
echo "run as SUDO or ROOT user!  if not running as SUDO or ROOT user, feel free to hit CONTROL->C and start this script over again"
read

cd /var/www/html/TheBriarPatch
echo "Grabbin the necessary web and mail resources..."
sudo apt-get install apache2 php5 sendmail mailutils sendmail-bin -y

clear
echo "creating necessary BriarPatch resource files"

sudo mkdir ../../securedfiles
sudo cp index.html ../
touch iPhoneTraffic.txt
touch LinuxTraffic.txt
touch WindowsTraffic.txt
touch maliciousscanner
touch refreshornot
touch ../../securedfiles/emails
touch ../../securedfiles/userandpass

echo -n "BriarPatch:ce0282260749002c72e7a1233ceb2eb4d6a65dc61cdefaba5870375ef1e35762f018c6f1d0abb5496f506dd48db392dff2d1f813597c306a60e2185f167c33ca">../../securedfiles/userandpass

#setup email
echo "ok, time to configure email settings"

echo "what is your gmail email address?  Please enter it below and hit enter"
read emailaddr

echo "what is your gmail password?  this will be encrypted.  Note: if using 2-factor, create an app password and enter that here"
read emailpasswd

echo -n "BriarPatch:$emailaddr">../../securedfiles/emails

echo "Would you like to enable automatic refresh every 60 seconds? Please enter Y or N.  This can be changed later if you like."
read refresh

echo "Would you like to enable the malicious scanner?  Y or N.  This can be changed later if you like."
read scanner

if [ "$refresh" == "Y" ]; then
echo "1">refreshornot
fi
echo "done."
if [ "$scanner" == "Y" ]; then
echo "1">maliciousscanner
fi
echo "done."

sudo chown www-data:www-data ../../securedfiles
sudo chown www-data:www-data ../../securedfiles/*
sudo chown www-data:www-data refreshornot
sudo chown www-data:www-data iPhoneTraffic.txt
sudo chown www-data:www-data LinuxTraffic.txt
sudo chown www-data:www-data WindowsTraffic.txt
sudo chown www-data:www-data maliciousscanner
sudo chown www-data:www-data suriretention.sh
sudo chown www-data:www-data broretention.sh

clear

echo "granting access to www-data apache user to purge old suricata and bro logs"
sudo sed -i -e '$awww-data    ALL=(ALL:ALL) NOPASSWD: /var/www/html/suriretention.sh' /etc/sudoers
sudo sed -i -e '$awww-data    ALL=(ALL:ALL) NOPASSWD: /var/www/html/broretention.sh' /etc/sudoers

#install/configure apache ssl cert
echo "Creating certificate(s).  Recommend change defaults especially the Internet Widgets as that will trigger an annoying IDS alert from suricata"
echo "here's what mine looks like:"

echo "Country Name (2 letter code) [AU]:US"
echo "State or Province Name (full name) [Some-State]:KY"
echo "Locality Name (eg, city) []:yourcityhere"
echo "Organization Name (eg, company) [Internet Widgits Pty Ltd]:TheBriarPatch"
echo "Organizational Unit Name (eg, section) []:BriarIDS"
echo "Common Name (e.g. server FQDN or YOUR name) []:your pi ip address here"
echo "Email Address []:youremail@gmail.com"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout thebriarpatch.key -out thebriarpatch.crt
sudo mkdir /var/www/certs
sudo mv thebriarpatch.key ../../certs
sudo mv thebriarpatch.crt ../../certs
clear
echo "adding certs to default-ssl.conf file"
echo "making copy of old config..."
sudo cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.old
echo "adding in your certs"
sudo sed -i '/ssl-cert-snakeoil.pem/c\SSLCertificateFile   \/var\/www\/certs\/thebriarpatch.crt' /etc/apache2/sites-available/default-ssl.conf
sudo sed -i '/ssl-cert-snakeoil.key/c\SSLCertificateKeyFile \/var\/www\/certs\/thebriarpatch.key' /etc/apache2/sites-available/default-ssl.conf

echo "enabling your newly configured ssl site!"
sudo a2enmod ssl
sudo a2enmod headers
sudo a2ensite default-ssl
sudo service apache2 restart

clear
echo "Setting up mail..."
sudo mkdir -m 700 /etc/mail/authinfo/
cd /etc/mail/authinfo/

echo "AuthInfo: \"U:root\" \"I:$emailaddr\" \"P:$emailpasswd\"">gmail-auth
sudo makemap hash gmail-auth < gmail-auth

sudo cp /var/www/html/TheBriarPatch/sendmail.mc /etc/mail/
sudo make -C /etc/mail
sudo /etc/init.d/sendmail reload

echo "adding in an entry for your hosts config file to respond kindly to mail relay and domain stuff"
echo 127.0.0.1       $HOSTNAME localhost.localdomain $HOSTNAME.local $HOSTNAME.localdomain>>/etc/hosts
echo "done."

echo "sending a test email now!"
echo "My message" | mail -s test $emailaddr


echo "ok, that should do it."
echo "Now go browse to https://raspberrypi.local/TheBriarPatch.php and explore!"