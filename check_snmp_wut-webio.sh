#!/bin/bash
#################################################################################
# Script:       check_snmp_wut-webio
# Author:       Michael Geschwinder (Maerkischer-Kreis)
# Description:  Plugin for Nagios/Icinga to check an W&T Web IO Thermometer
#               device with SNMP (v1).
# History:
# 20180401      Created plugin (types: temp, humidity, pressure
#
#################################################################################
# Usage:        ./check_snmp_wut-webio.sh -H host -c community -t type [-w warning] [-c critical]
#################################################################################

help="check_snmp_wut-webio (c) 2018 Michael Geschwinder published under GPL license
\nUsage: ./check_snmp_wut-webio.sh -H host [-c community] -t type [-w warning] [-c critical]
\nRequirements: snmpget, awk, sed\n
\nOptions: \t-H hostname\n\t\t-C Community (to be defined in snmp settings on APC, default public)\n\t\t-t Type to check, see list below
\t\t-w Warning Threshold (optional)\n\t\t-c Critical Threshold (optional)\n
\nTypes:\t\ttemp -> Checks the status of the battery
\t\thumidity -> Checks the temperature of the battery
\t\tpressure -> Oututs some general information of the device"

##########################################################
# Nagios exit codes and PATH
##########################################################
STATE_OK=0              # define the exit code if status is OK
STATE_WARNING=1         # define the exit code if status is Warning
STATE_CRITICAL=2        # define the exit code if status is Critical
STATE_UNKNOWN=3         # define the exit code if status is Unknown
PATH=$PATH:/usr/local/bin:/usr/bin:/bin # Set path


##########################################################
# Debug Ausgabe aktivieren
##########################################################
DEBUG=0

##########################################################
# Debug output function
##########################################################
function debug_out {
        if [ $DEBUG -eq "1" ]
        then
                datestring=$(date +%d%m%Y-%H:%M:%S)
                echo -e $datestring DEBUG: $1
        fi
}

###########################################################
# Check if programm exist $1
###########################################################
function check_prog {
        if ! `which $1 1>/dev/null`
        then
                echo "UNKNOWN: $1 does not exist, please check if command exists and PATH is correct"
                exit ${STATE_UNKNOWN}
        else
                debug_out "OK: $1 does exist"
        fi
}

############################################################
# Check Script parameters and set dummy values if required
############################################################
function check_param {
        if [ ! $host ]
        then
                echo "No Host specified... exiting..."
                exit $STATE_UNKNOWN
        fi

        if [ ! $community ]
        then
                debug_out "Setting default community (public)"
                community="public"
        fi
        if [ ! $type ]
        then
                echo "No check type specified... exiting..."
                exit $STATE_UNKNOWN
        fi
        if [ ! $warning ]
        then
                debug_out "Setting dummy warn value "
                warning=999
        fi
        if [ ! $critical ]
        then
                debug_out "Setting dummy critical value "
                critical=999
        fi
}



############################################################
# Get SNMP Value
############################################################
function get_snmp {
        oid=$1
        snmpret=$(snmpget -v1 -c $community -mALL $host $oid)
        if [ $? == 1 ]
        then
                exit $STATE_UNKNOWN
        else
                if [ "$2" == "" ]
                then
                        echo $snmpret | awk '{print $4}'
                else
                        echo $snmpret | cut -d "\"" -f$2
                fi
        fi

}

#################################################################################
# Display Help screen
#################################################################################
if [ "${1}" = "--help" -o "${#}" = "0" ];
       then
       echo -e "${help}";
       exit $STATE_UNKNOWN;
fi

################################################################################
# check if requiered programs are installed
################################################################################
for cmd in snmpget awk sed;do check_prog ${cmd};done;

################################################################################
# Get user-given variables
################################################################################
while getopts "H:C:t:w:c:o:" Input;
do
       case ${Input} in
       H)      host=${OPTARG};;
       C)      community=${OPTARG};;
       t)      type=${OPTARG};;
       w)      warning=${OPTARG};;
       c)      critical=${OPTARG};;
       o)      moid=${OPTARG};;
       *)      echo "Wrong option given. Please use options -H for host, -C for SNMP-Community, -t for type, -w for warning and -c for critical"
               exit 1
               ;;
       esac
done

debug_out "Host=$host, Community=$community, Type=$type, Warning=$warning, Critical=$critical"

check_param
#################################################################################
# Switch Case for different check types
#################################################################################
case ${type} in

temp)
        set -e
        ret=$(get_snmp "1.3.6.1.4.1.5040.1.2.16.1.4.1.1.1")
        set +e
        temp=$(echo "$ret * 0.1" | bc -l )
        perf="temp=$temp;$warning;$critical;0;60"
        temp_int=$(echo $temp | cut -d "." -f1 )
        if [ $temp_int -ge $critical ]
        then
                echo "CRITICAL: Temperature $temp C° is higher than $critical C|$perf°"
                exit $STATE_CRITICAL
        elif [ $temp_int -ge $warning ]
        then
                echo "WARNING: Temperature $temp C° is higher than $warning C|$perf°"
                exit $STATE_WARNING
        else
                echo "OK: Temperature is $temp C|$perf"
                exit $STATE_OK
        fi
;;
temp-alt)
        set -e
        ret=$(get_snmp "1.3.6.1.4.1.5040.1.2.37.1.3.1.1.1" 2)
        set +e
        temp=$(echo "$ret" | sed 's/,/./g' | sed 's/ //g')
        perf="temp=$temp;$warning;$critical;0;60"
        temp_int=$(echo $temp | cut -d "." -f1 )
        if [ $temp_int -ge $critical ]
        then
                echo "CRITICAL: Temperature $temp C° is higher than $critical C|$perf°"
                exit $STATE_CRITICAL
        elif [ $temp_int -ge $warning ]
        then
                echo "WARNING: Temperature $temp C° is higher than $warning C|$perf°"
                exit $STATE_WARNING
        else
                echo "OK: Temperature is $temp C|$perf"
                exit $STATE_OK
        fi
;;
temp-alt2)
        set -e
        ret=$(get_snmp "1.3.6.1.4.1.5040.1.2.8.1.4.1.1.1")
        set +e
        temp=$(echo "$ret * 0.1" | bc -l )
        perf="temp=$temp;$warning;$critical;0;60"
        temp_int=$(echo $temp | cut -d "." -f1 )
        if [ $temp_int -ge $critical ]
        then
                echo "CRITICAL: Temperature $temp C° is higher than $critical C|$perf°"
                exit $STATE_CRITICAL
        elif [ $temp_int -ge $warning ]
        then
                echo "WARNING: Temperature $temp C° is higher than $warning C|$perf°"
                exit $STATE_WARNING
        else
                echo "OK: Temperature is $temp C|$perf"
                exit $STATE_OK
        fi
;;
humidity)
        set -e
        ret=$(get_snmp "1.3.6.1.4.1.5040.1.2.16.1.4.1.1.2")
        set +e
        hum=$(echo "$ret * 0.1" | bc -l )
        perf="humidity=$hum%;0;0;0;100"
        echo "OK: Humidity is $hum %|$perf"
        exit $STATE_OK
;;

humidity-alt)
        set -e
        ret=$(get_snmp "1.3.6.1.4.1.5040.1.2.37.1.3.1.1.2" 2)
        set +e
#        hum=$(echo "$ret * 0.1" | bc -l )
        hum=$(echo $ret | sed 's/,/./g')
        perf="humidity=$hum%;0;0;0;100"
        echo "OK: Humidity is $hum %|$perf"
        exit $STATE_OK
;;
pressure)
        set -e
        ret=$(get_snmp 1.3.6.1.4.1.5040.1.2.16.1.4.1.1.3 )
        set +e
        pres=$(echo "$ret * 0.1" | bc -l )
        perf="pressure=$pres;;;"
        echo "OK: Pressure is $pres hPa |$perf"
        exit $STATE_OK
;;

pressure-alt)
        set -e
        ret=$(get_snmp "1.3.6.1.4.1.5040.1.2.37.1.3.1.1.3" 2 )
        set +e
        pres=$(echo $ret | sed 's/,/./g')
        perf="pressure=$pres;;;"
        echo "OK: Pressure is $pres hPa |$perf"
        exit $STATE_OK
;;



*)
        echo "Wrong option given! Use --help"
        exit $STATE_UNKNOWN
;;
esac
