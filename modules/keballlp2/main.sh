#!/bin/bash
. /var/www/html/openWB/openwb.conf
rekwh='^[-+]?[0-9]+\.?[0-9]*$'
re='^-?[0-9]+$'
#sleep 3
counter=0
while [[ -e /var/www/html/openWB/ramdisk/kebasync && $counter < 4 ]]; do
sleep 1
counter=$((counter + 1))
done
echo 0 > /var/www/html/openWB/ramdisk/kebasync
if [[ $counter == "4" ]] ; then
	  dtime=$(date +"%T")
   echo " $dtime keba2 sleep overrun "
fi
echo 0 > /var/www/html/openWB/ramdisk/kebasync
dtime=$(date +"%T")
#echo " $dtime keba2 status $kebaiplp2 "
nc -ul 7090 >/var/www/html/openWB/ramdisk/keballlp2 &
pidnc=$!
disown
echo -n "report 3" | socat - UDP-DATAGRAM:$kebaiplp2:7090
sleep 1
outputte1=$(tr -d '\0' </var/www/html/openWB/ramdisk/keballlp2)
echo $outputte1 > /var/www/html/openWB/ramdisk/keballlp2r3
output=$(echo $outputte1 | tr -d '\n' | sed 's/\}.*/\}/')
echo $output > /var/www/html/openWB/ramdisk/keballlp2r3x
echo -n > /var/www/html/openWB/ramdisk/keballlp2
#read plug and chargingstatus
echo -n "report 2" | socat - UDP-DATAGRAM:$kebaiplp2:7090
sleep 1
outputte1=$(tr -d '\0' </var/www/html/openWB/ramdisk/keballlp2)
echo $outputte1 > /var/www/html/openWB/ramdisk/keballlp2r2
output1=$(echo $outputte1 | tr -d '\n' | sed 's/\}.*/\}/')
echo $output1 > /var/www/html/openWB/ramdisk/keballlp2r2x
#
kill $pidnc
rm /var/www/html/openWB/ramdisk/keballlp2
rm /var/www/html/openWB/ramdisk/kebasync
rep3=$(echo $output | jq '.ID') 
rep2=$(echo $output1 | jq '.ID') 
rep3="${rep3%\"}"
rep3="${rep3#\"}"
rep2="${rep2%\"}"
rep2="${rep2#\"}"

if [[ $rep3 == "3" ]] ; then
   watt=$(echo $output | jq '.P') 
   watt=$(echo "($watt / 1000)/1" |bc)
   if [[ $watt =~ $rekwh ]] ; then
	     echo $watt > /var/www/html/openWB/ramdisk/llaktuells1
    fi

    lla1=$(echo $output | jq '.I1') 
    lla1=$(echo "scale=2;$lla1 / 1000" |bc)
    lla2=$(echo $output | jq '.I2') 
    lla2=$(echo "scale=2;$lla2 / 1000" |bc)
    lla3=$(echo $output | jq '.I3') 
    lla3=$(echo "scale=2;$lla3 / 1000" |bc)
    if [[ $lla1 =~ $rekwh ]] ; then
	      echo $lla1 > /var/www/html/openWB/ramdisk/llas11
    fi
    if [[ $lla2 =~ $rekwh ]] ; then
	      echo $lla2 > /var/www/html/openWB/ramdisk/llas12
    fi
    if [[ $lla3 =~ $rekwh ]] ; then
	      echo $lla3 > /var/www/html/openWB/ramdisk/llas13
     fi
    llv1=$(echo $output | jq '.U1') 
    llv2=$(echo $output | jq '.U2') 
    llv3=$(echo $output | jq '.U3') 
    if [[ $llv1 =~ $re ]] ; then
	      echo $llv1 > /var/www/html/openWB/ramdisk/llvs11
    fi
    if [[ $llv2 =~ $re ]] ; then
	      echo $llv2 > /var/www/html/openWB/ramdisk/llvs12
    fi
    if [[ $llv3 =~ $re ]] ; then
	      echo $llv3 > /var/www/html/openWB/ramdisk/llvs13
    fi
    chargedwh=$(echo $output | jq '."E pres"') 
#   totalwh=$(echo $output | jq '."E total"') 
#   llwh=$(echo $chargedwh + $totalwh | bc)
    llwh=$(echo $output | jq '."E total"') 
    llkwh=$(echo "scale=3;$llwh / 10000" | bc -l)
    if [[ $llkwh =~ $rekwh ]] ; then
       	echo $llkwh > /var/www/html/openWB/ramdisk/llkwhs1
    fi
fi
if [[ $rep2 == "2" ]] ; then
   newplug=$(echo $output1 | jq '.Plug')
   newstatus=$(echo $output1 | jq '.State')
#Plug Status 3 Kabel ist eingesteckt an der Ladestation, kein Auto
#Plug Status 7 Kabel ist eingesteckt Ladestation und Auto verriegelt. 
#Status 2 ready for charging
#Status 3 charging
   if [[ $newplug == "7" ]] ; then
      echo 1 > /var/www/html/openWB/ramdisk/plugstats1
   else          
      echo 0 > /var/www/html/openWB/ramdisk/plugstats1
   fi
   if [[ $newstatus == "3" ]] ; then
      echo 1 > /var/www/html/openWB/ramdisk/chargestats1
   else          
      echo 0 > /var/www/html/openWB/ramdisk/chargestats1
   fi
fi





