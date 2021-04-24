#!/bin/sh

# poor's man 'duma
# (c) 2018 sfortis


### user variables
tmpfile=/tmp/_tmpcurl.tmp
detectlist=/mnt/sandisk-usb/pmd/ww2-server-detect.txt
banlist=/mnt/sandisk-usb/pmd/ww2-server-ban.txt
input=asd

echo " _____                 _____         ____                "
echo "|  _  |___ ___ ___ ___|     |___ ___|    \ _ _ _____ ___ "
echo "|   __| . | . |  _|_ -| | | | .'|   |  |  | | |     | .'|"
echo "|__|  |___|___|_| |___|_|_|_|__,|_|_|____/|___|_|_|_|__,|"

echo "▒sfortis 2020"
echo ""

rm -f $tmpfile

while [ "$input" != "x" ]; do

echo ">>start playing. trying to detect Activision COD server..."

        tophost=`tcpdump -tnn -c 300 -i any dst port 3074 and not src port 3074 | awk -F "." '{print $1"."$2"."$3"."$4}' | sort | uniq -c | sort -nr | head -1 | awk '{print $3 "\t"}'` >/dev/null 2>&1
        srvip="$(echo -e "${tophost}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        case "$srvip" in *192.168*) continue; esac
        echo "Server detected : $srvip"

echo ">>Getting geographical IP data..."
#curl -s ipinfo.io/$srvip > $tmpfile
echo $srvip
curl -s "https://ipapi.co/$srvip/json/" >$tmpfile
#curl -s "https://api.ipgeolocation.io/ipgeo?apiKey=b6c9cc5842cf40db87c9d637666aa6cb&ip=$srvip&output=json" > $tmpfile

#cat $tmpfile

city=`cat $tmpfile | jq -r .city`
country=`cat $tmpfile | jq -r .country`
country_name=`cat $tmpfile | jq -r .country_name`
hostname=`nslookup $srvip 8.8.8.8 | awk 'END{print}' | awk '/^Address 1: / { print $4 }'`
org=`cat $tmpfile | jq -r .org`

if [ "$hostname" == null ]; then hostname="$srvip"; fi

echo "---------------------------------"
echo "You're playing on server $hostname (ISP: $org)" && echo "located on $city, $country_name"
echo "$srvip $city $country" >>$detectlist
#ping -c3 -q $srvip |grep round-trip
#mtr -u -r -o "L ABWV MI" $srvip

#ping host
echo "---------------------------------"
nmap -sn -PU $srvip | awk 'NR==3'
echo "---------------------------------"

echo -e "\n"

echo -e "Do you want to BAN this host?"
read -n 1 -p "Press (1) to BAN IP, (5) to BAN SUBNET or (x) to quit or any other key to continue scan: " input

if [ "$input" = "1" ]; then
        echo -e "$srvip $city $country" >>$banlist
        echo -e "\n>>Banning IP $srvip\n"
        sh /jffs/scripts/firewall ban ip $srvip "COD $srvip $country"  >/dev/null 2>&1
        echo -e "Done."
elif [ "$input" = "5" ]; then
        echo -e "$srvip/24 $city $country" >>$banlist
        echo -e "\n>>Banning subnet $srvip/24\n"
        sh /jffs/scripts/firewall ban range "$srvip/24" "COD $srvip $country" >/dev/null 2>&1
        echo -e "Done."
else
        echo -e "\nOK, enjoy..."
fi


done
