An automatic script that uploads DDNS configuration to DNSPod.cn.

Fill the correct information at the top of the script an launch it!
NETINTERFACE: Network interface name. Eg. "eno1"
DOMAIN: target domain. Eg. "google.com"
SUBDOMAIN: target subdomain. Eg. "@" (reference to google.com), "www" (reference to www.google.com)
DNSPODTOKEN: ID,TOKEN. Eg. "13491,asdasdfasdfasdfsdf531fs5d1fa5sd1f"
ENABLEV6: Whether DDNS should be applied to IPV6. Eg. true, false
ENABLEV4: Whether DDNS should be applied to IPV4. Eg. true, false

Support crontab task.

The script will automatically add new dns records with remark "AUTODDNSMASK". If anything goes wrong, delete them in web console to reset.

How to get logintoken: https://support.dnspod.cn/Kb/showarticle/tsid/227/