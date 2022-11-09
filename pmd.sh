#!/bin/sh

# poor's man 'duma 
# (c) 2018-2022 sfortis


### user variables

usb_drive_path=/mnt/USB_DRIVE #<---- enter your usb drive path

tmpfile=/tmp/_tmpcurl.tmp
detectlist=$usb_drive_path/pmd/cod-server-detect.txt  # <---- prefer a USB path
banlist=$usb_drive_path/pmd/cod-server-ban.txt  # <---- prefer a USB path
input=a
datetime=`date +%d/%m/%Y-%H%M%S`

### check script home
if [ -d "$usb_drive_path/pmd" ];
then
    echo "script home found, good!"
else
	echo "script home not exists, creating..."
	mkdir $usb_drive_path/pmd
fi

echo " _____                 _____         ____                "
echo "|  _  |___ ___ ___ ___|     |___ ___|    \ _ _ _____ ___ "
echo "|   __| . | . |  _|_ -| | | | .'|   |  |  | | |     | .'|"
echo "|__|  |___|___|_| |___|_|_|_|__,|_|_|____/|___|_|_|_|__,|"
                                                         
echo "(c)sfortis 2020"
echo ""

rm -f $tmpfile 

while [ "$input" != "x" ]; do

echo ">>start playing. trying to detect Activision COD server..."

	tophost=`tcpdump -tnn -c 300 -i any dst port 3074 and not src port 3074 | awk -F "." '{print $1"."$2"."$3"."$4}' | sort | uniq -c | sort -nr | head -1 | awk '{print $5 "\t"}'` >/dev/null 2>&1 
	srvip="$(echo -e "${tophost}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
	case "$srvip" in *192.168*) continue; esac
	echo "Server detected : $srvip"

echo ">>Getting geographical IP data..."
echo $srvip

# choose your prefered ipgeolocation provider here

#curl -s "https://ipinfo.io/$srvip" > $tmpfile 
#curl -s "https://ipapi.co/$srvip/json/" >$tmpfile
curl -s "https://api.ipgeolocation.io/ipgeo?apiKey=YOURAPIKEY&ip=$srvip&output=json" > $tmpfile # <-- YOU NEED TO GET AN API KEY FROM https://app.ipgeolocation.io/

city=`cat $tmpfile | jq -r .city`
country=`cat $tmpfile | jq -r .country`
country_name=`cat $tmpfile | jq -r .country_name`
hostname=`nslookup $srvip 8.8.8.8 | awk 'END{print}' | awk '/^Address 1: / { print $4 }'`
org=`cat $tmpfile | jq -r .organization`

if [ "$hostname" == null ]; then hostname="$srvip"; fi 

echo "---------------------------------"
echo "You're playing on server $hostname (ISP: $org)" && echo "located on $city, $country_name"

#ping host
echo "---------------------------------"
lat=`nmap -sn -PU $srvip | awk 'NR==3' | cut -c13-19`
echo "ping: $lat"
echo "---------------------------------"

#update detectlist
egrep $srvip $detectlist
if [ $? -gt 0 ]
	then
	echo "$datetime - $srvip - $city - $country - $lat" >>$detectlist
	else
	echo "Server allready exists in detectlist"
fi

echo -e "\n"

echo -e "Do you want to BAN this host?"
read -n 1 -p "Press (1) to BAN IP, (2) to BAN SUBNET or (x) to quit or any other key to continue scan: " input 

if [ "$input" = "1" ]; then
	echo -e "$srvip $city $country" >>$banlist
	echo -e "\n>>Banning IP $srvip\n"
	sh firewall ban ip $srvip "COD $country $lat"  >/dev/null 2>&1
	echo -e "Done."
elif [ "$input" = "2" ]; then 
	subnet=`echo $srvip | awk -F. '{print $1"."$2"."$3".0"}'`
	echo -e "$subnet/24 $city $country" >>$banlist
	echo -e "\n>>Banning subnet $subnet/24\n"
	sh /jffs/scripts/firewall ban range "$subnet/24" "COD $country $lat" >/dev/null 2>&1
	echo -e "Done."
else
	echo -e "\nOK, enjoy..."
fi
            

done
