#!/bin/bash

if [[ "$#" -lt 1 ]]; then
    echo "$0 <filename> [--short]";
    exit;
fi

if [[ $1 == "-h" ]]; then
    echo "$0 <filename> [--short]";
    echo "$0 -h";
    exit;
fi

short_output=false;
if [[ $2 == "--short" ]]; then
    short_output=true;
fi

capture_info="$(capinfo $1)";

regex="\(([0-9]+) bytes\)";
[[ $(echo "$capture_info" | grep 'bytes: ') =~ $regex ]]
if [ -z "${BASH_REMATCH[1]}" ]; then
    total_bytes=0;
else
    total_bytes=${BASH_REMATCH[1]};
fi

regex="\(([0-9]+\.[0-9]+) seconds\)";
[[ $(echo "$capture_info" | grep 'duration: ') =~ $regex ]]
if [ -z "${BASH_REMATCH[1]}" ]; then
    duration=0;
else
    duration=${BASH_REMATCH[1]};
fi

regex=", ([0-9]+) bytes";
[[ $(echo "$capture_info" | grep 'tcp: ') =~ $regex ]]
if [ -z "${BASH_REMATCH[1]}" ]; then
    tcp_bytes=0;
else
    tcp_bytes=${BASH_REMATCH[1]};
fi

regex=", ([0-9]+) bytes";
[[ $(echo "$capture_info" | grep 'udp: ') =~ $regex ]]
if [ -z "${BASH_REMATCH[1]}" ]; then
    udp_bytes=0;
else
    udp_bytes=${BASH_REMATCH[1]};
fi

regex=", ([0-9]+) bytes";
[[ $(echo "$capture_info" | grep 'icmp: ') =~ $regex ]]
if [ -z "${BASH_REMATCH[1]}" ]; then
    icmp_bytes=0;
else
    icmp_bytes=${BASH_REMATCH[1]};
fi

mahp=$(capshow $1 --eth.type=IP \
| grep -oP '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(:[0-9]+|) --> [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(:[0-9]+|)' \
| sed -e 's/:[0-9]*//g' \
| sed -e 's/ --> / /g' \
| awk '{print $1 " " $2 "\n" $2 " " $1}' \
| sort \
| uniq -c \
| sort -nr \
| head -n 1);

mahp_1=$(echo $mahp | awk '{print $2}');
mahp_2=$(echo $mahp | awk '{print $3}');

mahp_info=$(capfilter -q --bpf "ip and host $mahp_1 and host $mahp_2" $1 | capinfo)

regex=", ([0-9]+) bytes";
[[ $(echo "$mahp_info" | grep 'tcp: ') =~ $regex ]]
if [ -z "${BASH_REMATCH[1]}" ]; then
    mahp_info_tcp=0;
else
    mahp_info_tcp=${BASH_REMATCH[1]};
fi

regex=", ([0-9]+) bytes";
[[ $(echo "$mahp_info" | grep 'udp: ') =~ $regex ]]
if [ -z "${BASH_REMATCH[1]}" ]; then
    mahp_info_udp=0;
else
    mahp_info_udp=${BASH_REMATCH[1]};
fi

regex=", ([0-9]+) bytes";
[[ $(echo "$mahp_info" | grep 'icmp: ') =~ $regex ]]
if [ -z "${BASH_REMATCH[1]}" ]; then
    mahp_info_icmp=0;
else
    mahp_info_icmp=${BASH_REMATCH[1]};
fi

if [ "$short_output" = true ] ; then
    echo "$total_bytes $duration $tcp_bytes $udp_bytes $icmp_bytes $mahp_1 $mahp_2 $mahp_info_tcp $mahp_info_udp $mahp_info_icmp";
else
    echo "Total bytes : $total_bytes bytes";
    echo "Duration    : $duration seconds";
    echo "TCP         : $tcp_bytes bytes";
    echo "UDP         : $udp_bytes bytes";
    echo "ICMP        : $icmp_bytes bytes";
    echo "MAHP        : ($mahp_1, $mahp_2)";
    echo "TCP (MAHP)  : $mahp_info_tcp bytes";
    echo "UDP (MAHP)  : $mahp_info_udp bytes";
    echo "ICMP (MAHP) : $mahp_info_icmp bytes";
fi
