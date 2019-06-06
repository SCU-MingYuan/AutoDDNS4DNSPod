# /bin/sh
# Author SalimTerryLi(lhf2613@gmail.com)
# dependence: ifconfig nslookup curl grep sed

NETINTERFACE="eno1"
DOMAIN="google.com"
SUBDOMAIN="@"
DNSPODTOKEN="23333,2333333333cd333333ab333333333333"
ENABLEV6=true
ENABLEV4=true

###################################
## Run time environment
__subdomain=""
__domainidv6=""
__domainidv4=""
__cmd_query="curl -X POST https://dnsapi.cn/Record.List -d login_token=$DNSPODTOKEN&format=xml&domain=$DOMAIN&sub_domain=$SUBDOMAIN"
$__cmd_query > ddns_query_result.tmp
__cmd_update_v6="curl -X POST https://dnsapi.cn/Record.Ddns -d login_token=$DNSPODTOKEN&format=json&domain=$DOMAIN&record_line_id=0&sub_domain=$SUBDOMAIN"
__cmd_update_v4="curl -X POST https://dnsapi.cn/Record.Ddns -d login_token=$DNSPODTOKEN&format=json&domain=$DOMAIN&record_line_id=0&sub_domain=$SUBDOMAIN"
__cmd_create_v6="curl -X POST https://dnsapi.cn/Record.Create -d login_token=$DNSPODTOKEN&format=xml&domain=$DOMAIN&sub_domain=$SUBDOMAIN&record_type=AAAA&record_line_id=0"
__cmd_create_v4="curl -X POST https://dnsapi.cn/Record.Create -d login_token=$DNSPODTOKEN&format=xml&domain=$DOMAIN&sub_domain=$SUBDOMAIN&record_type=A&record_line_id=0"
__cmd_remark="curl -X POST https://dnsapi.cn/Record.Remark -d login_token=$DNSPODTOKEN&format=json&domain=$DOMAIN&remark=AUTODDNSMARK&record_id="
__isNewCreatedV6=false
__isNewCreatedV4=false

echo \
'begin{recbegin=0;itembegin=0;}
{if($1=="records"){recbegin=1;next;}
else if($1=="/records"){recbegin=0;next;}
if(recbegin==1){
if($1=="item"){itembegin=1;next;}
else if($1=="/item" && itembegin==1){if(query=="id"){print id}else if(query=="address"){print value};itembegin=0;exit;}
if(itembegin==1){
if($1=="id"){id=$2}
if($1=="type"){type=$2;if(type!=regtype){itembegin=0;next;}}
if($1=="name"){name=$2;if(name!=subdomain){itembegin=0;next;}}
if($1=="value"){value=$2}
if($1=="remark"){if($2!="AUTODDNSMARK"){itembegin=0;next;}}
}}}' > auto_ddns_info.awk
###################################
if [ $SUBDOMAIN != "@" ]
then
	__subdomain="$SUBDOMAIN."
fi
###################################
## Get local ip
if [ $ENABLEV6 = true ]
then
	IPV6ADD=`ifconfig $NETINTERFACE | grep "inet6" | grep "global" | awk '{print $2;exit;}'`
fi
if [ $ENABLEV4 = true ]
then
	IPV4ADD=`ifconfig $NETINTERFACE | grep "inet" | awk '{print $2;exit;}'`
fi
###################################
## Get resolved ip, not being used.
if [ $ENABLEV6 = true ]
then
	LOOKUPV6=`nslookup -query=AAAA $__subdomain$DOMAIN | grep "Address:" | awk '{if(NR==2){print $2;}}'`
fi
if [ $ENABLEV4 = true ]
then
	LOOKUPV4=`nslookup -query=A $__subdomain$DOMAIN | grep "Address:" | awk '{if(NR==2){print $2;}}'`
fi
###################################
## Check if record with specific remark exists. If not, create it.
if [ $ENABLEV6 = true ]
then
	__domainidv6=`cat ddns_query_result.tmp | sed 's/</ /;s/>/ /;s/</ /;s/>/ /' | awk -v subdomain="@" -v regtype="AAAA" -v query="id" -f auto_ddns_info.awk`
	if [ "$__domainidv6" = "" ]
	then
		echo "DDNSv6 record not found!"
		__domainidv6=`$__cmd_create_v6"&value=$IPV6ADD" | grep "<id>" | sed 's/<id>//;s/<\/id>//'`
		$__cmd_remark"$__domainidv6"
echo $__domainidv6
		__isNewCreatedV6=true
	fi
fi
__domainidv4=`cat ddns_query_result.tmp | sed 's/</ /;s/>/ /;s/</ /;s/>/ /' | awk -v subdomain="@" -v regtype="A" -v query="id" -f auto_ddns_info.awk`
if [ $ENABLEV4 = true ]
then
	if [ "$__domainidv4" = "" ]
	then
		echo "DDNSv4 record not found!"
		__domainidv4=`$__cmd_create_v4"&value=$IPV4ADD" | grep "<id>" | sed 's/<id>//;s/<\/id>//'`
		$__cmd_remark"$__domainidv4"
		__isNewCreatedV4=true
	fi
fi
###################################
## Update cache.
if [ $__isNewCreatedV6 = true -o $__isNewCreatedV4 = true ]
then
	$__cmd_query > ddns_query_result.tmp
fi
###################################
if [ $ENABLEV6 = true -a $__isNewCreatedV6 = false ]
then
	__storedip=`cat ddns_query_result.tmp | sed 's/</ /;s/>/ /;s/</ /;s/>/ /' | awk -v subdomain="@" -v regtype="AAAA" -v query="address" -f auto_ddns_info.awk`
	echo -n $__storedip | grep "$IPV6ADD" >/dev/null
	if [ $? = 0 ]
	then
		echo "IPV6 not changed."
	else
		echo "Update AAAA"
		$__cmd_update_v6"&value=\"$IPV6ADD\"&record_id=$__domainidv6"
		echo
	fi
fi
if [ $ENABLEV4 = true -a $__isNewCreatedV4 = false ]
then
	__storedip=`cat ddns_query_result.tmp | sed 's/</ /;s/>/ /;s/</ /;s/>/ /' | awk -v subdomain="@" -v regtype="A" -v query="address" -f auto_ddns_info.awk`
	echo -n $__storedip | grep "$IPV4ADD" >/dev/null
	if [ $? = 0 ]
	then
		echo "IPV4 not changed."
	else
		echo "Update A"
		$__cmd_update_v4"&value=$IPV4ADD&record_id=$__domainidv4"
		echo
	fi
fi
###################################
## Clean up
rm ddns_query_result.tmp
rm auto_ddns_info.awk