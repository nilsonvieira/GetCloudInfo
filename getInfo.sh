#!/bin/bash

export AWS_ACCESS_KEY_ID=`cat env | grep ACCESS_KEY_ID  | cut -d"=" -f2`
export AWS_SECRET_ACCESS_KEY=`cat env | grep SECRET_ACCESS_KEY  | cut -d"=" -f2`
export AWS_DEFAULT_REGION=`cat env | grep DEFAULT_REGION  | cut -d"=" -f2`

_LASTDAY=`cal $(date +"%m %Y") | awk 'NF {DAYS = $NF}; END {print DAYS}'`
_MONTH=`date +'%m' -d 'now'`
_YEAR=`date +%Y`

aws ec2 describe-instances >> /tmp/aws-instances 
# aws ce get-cost-and-usage --time-period Start=$_YEAR-$_MONTH-01,End=$_YEAR-$_MONTH-$_LASTDAY --granularity MONTHLY --metrics "BlendedCost" "UnblendedCost" "UsageQuantity" >> /tmp/aws-costs
aws ce get-cost-and-usage --time-period Start=$_YEAR-01-01,End=$_YEAR-12-31 --granularity MONTHLY --metrics "BlendedCost" "UnblendedCost" "UsageQuantity" >> /tmp/aws-costs
_COUNT=`cat /tmp/aws-instances | jq '.[] | {NAME: .[].Instances[].Tags[].Value}' | grep NAME | wc -l`
i=0
echo -e "INSTANCIA\tIP_PUBLICO\tIP_PRIVADO\tSTATUS" >> /tmp/file
while [ $i -lt $_COUNT ]
    do
        _NAME=`cat /tmp/aws-instances | jq ".[] | {NAME: .[$i].Instances[].Tags[0].Value}" 2>/dev/null | grep NAME | awk '{print$2}' | sed -e 's/"/ /g'` 
        _PUBLICIP=`cat /tmp/aws-instances | jq ".[] | {PUBLIC_IP: .[$i].Instances[].NetworkInterfaces[].PrivateIpAddresses[].Association.PublicIp}" 2>/dev/null | grep PUBLIC_IP | awk '{print$2}' | sed -e 's/"/ /g'` 
        _PRIVATEIP=`cat /tmp/aws-instances | jq ".[] | {PRIVATE_IP: .[$i].Instances[].NetworkInterfaces[].PrivateIpAddresses[].PrivateIpAddress}" 2>/dev/null | grep PRIVATE_IP | awk '{print$2}'| sed -e 's/"/ /g'`
        _STATE=`cat /tmp/aws-instances | jq ".[] | {STATE: .[$i].Instances[].State.Name}" 2>/dev/null | grep STATE | awk '{print$2}' |  sed -e 's/"/ /g'`
        
        echo -e "${_NAME}\t${_PUBLICIP}\t${_PRIVATEIP}\t${_STATE}" >> /tmp/file

    i=$(( $i + 1 ))
    done

_INSTANCE=`cat /tmp/file`
_COSTS=`cat /tmp/aws-costs | jq -r ".[] | .[].Total.BlendedCost.Amount" | sed '1s/^/JAN\t/' | sed '2s/^/FEV\t/' | sed '3s/^/MAR\t/' | sed '4s/^/ABR\t/' |  sed '5s/^/MAI\t/' | sed '6s/^/JUN\t/' | sed '7s/^/JUL\t/' | sed '8s/^/AGO\t/' | sed '9s/^/SET\t/' | sed '10s/^/OUT\t/' | sed '11s/^/NOV\t/' | sed '12s/^/DEZ\t/'`
echo "---------------------------------------------------------------------------"
echo "                     INFORMACOES DAS INSTANCIAS                            "
echo "---------------------------------------------------------------------------"
echo -e "${_INSTANCE}" | column -t
echo "---------------------------------------------------------------------------"
echo "                      INFORMACOES DOS CUSTOS                               "
echo "---------------------------------------------------------------------------"
echo -e "MES\tVALORES"
echo "---------------------------------------------------------------------------"
echo -e "$_COSTS"
echo "---------------------------------------------------------------------------"

rm /tmp/file
rm /tmp/aws-instances
rm /tmp/aws-costs
