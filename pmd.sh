#!/bin/sh

# poor's man 'duma 
# (c) 2018 sfortis


### user variables
tmpfile=/tmp/_tmpcurl.tmp
detectlist=/jffs/ww2-server-detect.txt
banlist=/jffs/pmd/ww2-server-ban.txt

echo " ######################################################################################################### "
echo "#                                                                                                         #" 
echo "#  ______                      __                                         _____                           #"
echo "# |   __ \.-----..-----..----.|  |.-----.    .--------..---.-..-----.    |     \ .--.--..--------..---.-. #"
echo "# |    __/|  _  ||  _  ||   _| |_||__ --|    |        ||  _  ||     |    |  --  ||  |  ||        ||  _  | #"
echo "# |___|   |_____||_____||__|      |_____|    |__|__|__||___._||__|__|    |_____/ |_____||__|__|__||___._| #"
echo "#                                                                                                         #"
echo "# (c) 2018 sfortis                                                                                        #"
echo " ######################################################################################################### "                                                                                                       
echo ""

rm -f $tmpfile 

echo ">>start playing online. trying to detect Activision COD server..."

tophost=`tcpdump -tnn -c 500 -i any dst port 3074 | awk -F "." '{print $1"."$2"."$3"."$4}' | sort | uniq -c | sort -nr | head -1 | awk '{print $3 "\t"}'` >/dev/null 2>&1 
srvip="$(echo -e "${tophost}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
echo "Server detected : $srvip"

echo ">>Getting geographical IP data..."
curl -s ipinfo.io/$srvip > $tmpfile 

city=`cat $tmpfile | jq -r .city`
country=`cat $tmpfile | jq -r .country`
hostname=`cat $tmpfile | jq -r .hostname`
org=`cat $tmpfile | jq -r .org`

if [ "$hostname" == null ]; then hostname="$srvip"; fi 

echo "You're playing on server $hostname ($org), located on $city,$country"
echo "$srvip $city $country" >>$detectlist

ping -c3 -q $srvip |grep round-trip

echo -e "\n"

echo -e "Do you want to BAN this host?"
read -n 1 -p "Press (1) to BAN IP, (2) to BAN SUBNET, (9) to BAN COUNTRY [$country] or any other key to CANCEL : " input 

if [ "$input" = "1" ]; then
	echo -e "$srvip $city $country" >>$banlist
	echo -e "\n>>Banning IP $srvip\n"
	sh /jffs/scripts/firewall ban ip $srvip "COD $hostname $country" >/dev/null 2>&1
	echo -e "Done."
elif [ "$input" = "2" ]; then 
	echo -e "$srvip/24 $city $country" >>$banlist
	echo -e "\n>>Banning subnet $srvip/24\n"
	sh /jffs/scripts/firewall ban range "$srvip/24" "COD $hostname $country" >/dev/null 2>&1
	echo -e "Done."
elif [ "$input" = "9" ]; then
        echo -e "\nBanning country $country\n"
        sh /jffs/scripts/firewall ban country "$country" >/dev/null 2>&1
	echo -e "Done."
else
	echo -e "\nOK, enjoy..."
fi
            
