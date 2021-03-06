#!/bin/sh

echo 1 > /proc/sys/kernel/printk
if [[ $3 == *.log ]]; then
	LOGFILE=$3
fi
TEST_NAME="[boradr-reach] - [boradr-reach Connection]"
TEST_PARAMS="$1 $2 $3 $4 $5"

function Test_Function
{
	INTERFACE=$1
	#DHCP_TIMEOUT=$2
	PING_TIMEOUT=$2
	HOST_IP=$3
	SLAVE_IP=$4
	HOST_OR_SLAVE=$5
	
	echo "HOST_IP=$HOST_IP"
	echo "SLAVE_IP=$SLAVE_IP"
	#PINGLOC=$4
	if [ -z "$INTERFACE" ]; then
	    INTERFACE=eth0
	fi
	
	if [ -z "$DHCP_TIMEOUT" ]; then
		DHCP_TIMEOUT=5
	fi
	
	if [ -z "$PING_TIMEOUT" ]; then
		PING_TIMEOUT=5
	fi

	if [ -z "$PINGLOC" ]; then
	    SKIPPINGTEST=1
#	    echo "Skipping ping test"
	fi
	
	if [[ $HOST_OR_SLAVE == "0" ]]; then 
		echo "Be Master"
		echo 1 >  /sys/devices/soc0/soc/2100000.aips-bus/2188000.ethernet/2188000.ethernet:07/tja1100/phy_master
		if ! ifconfig $INTERFACE down; then                      
            echo "Device $INTERFACE not found!"                
            return 1                                           
    fi
	else 
		echo "Be Slave"
		echo 0 >  /sys/devices/soc0/soc/2100000.aips-bus/2188000.ethernet/2188000.ethernet:07/tja1100/phy_master
		if ! ifconfig $INTERFACE down; then                      
            echo "Device $INTERFACE not found!"                
            return 1                                           
		fi
	fi
	
	sleep 1
	
	if [[ $HOST_OR_SLAVE == "0" ]]; then 
		if ! ifconfig $INTERFACE $HOST_IP up; then
			echo "Device $INTERFACE not found!"
			return 1
		fi
	else 
		if ! ifconfig $INTERFACE $SLAVE_IP up; then
			echo "Device $INTERFACE not found!"
			return 1
		fi
	fi
	
	sleep 3
	
	
	if [[ $HOST_OR_SLAVE == "0" ]]; then
		echo "$HOST_IP ping $SLAVE_IP"
		if ! ping $SLAVE_IP -I $INTERFACE -c $PING_TIMEOUT; then # HOST ping SLAVE IP
			echo "Could not connect to internet"
			return 1
		fi
	else
		echo "$SLAVE_IP ping $HOST_IP"
		if ! ping $HOST_IP -I $INTERFACE -c $PING_TIMEOUT; then #  SLAVE ping HOST IP
			echo "Could not connect to internet"
			return 1
		fi
	fi

	

#	ifconfig $INTERFACE down	
	return 0			
}

if [ -n "$LOGFILE" ]; then
	echo "$TEST_NAME" > $LOGFILE
	echo "" >> $LOGFILE
	echo "$(date)" >> $LOGFILE
	echo "============================" >> $LOGFILE
fi
unset INTERACTIVE
if [ -n "$TEST_PROMPT_PRE" ]; then
	INTERACTIVE=1
	echo "Interactive Test $TEST_NAME"
	unset RESULT

	while [ -z "$RESULT" ]; do
		echo "   $TEST_PROMPT_PRE"

		if [ -z "$TEST_PROMPT_POST" ]; then
			echo -n "   Press any key to continue"
			read
            	else
                	sleep 2
            	fi

		#$TEST_COMMAND >> $LOGFILE 2>&1
		#RESULT=$?
		if [ -n "$LOGFILE" ]; then
			Test_Function $TEST_PARAMS >> $LOGFILE 2>&1
		else
			Test_Function $TEST_PARAMS
		fi
		RESULT=$?
		if [ -n "$TEST_PROMPT_POST" ]; then
			echo -n "   $TEST_PROMPT_POST (y/n/r[etry]): "
			read RESPONSE
			if [[ "$RESPONSE" == "y" ]]; then
				RESULT=0
			elif [[ "$RESPONSE" == "n" ]]; then
				RESULT=1
			else
				unset RESULT
			fi
            	fi
	done

	printf "%-60s: " "$TEST_NAME"
else
	if [ -n "$LOGFILE" ]; then
		printf "%-60s: " "$TEST_NAME"
		Test_Function $TEST_PARAMS >> $LOGFILE 2>&1
	else
		echo "Automated Test $TEST_NAME"
		echo ""
		Test_Function $TEST_PARAMS
	fi
	RESULT=$?
fi
if [ "$RESULT" == 0 ]; then
	if [ -n "$LOGFILE" ]; then
		echo "============================" >> $LOGFILE
        	echo "SUCCESS" >> $LOGFILE
	fi
	if [ -n "$INTERACTIVE" ]; then
		echo -en "SUCCESS\n"
		echo ""
	else
		echo -en "SUCCESS\n"
        fi
else
	if [ -n "$LOGFILE" ]; then
		echo "============================" >> $LOGFILE
        	echo "FAILURE" >> $LOGFILE
	fi
	if [ -n "$INTERACTIVE" ]; then
		echo -en "FAILURE\n"                    
		echo ""
	else
		echo -en "FAILURE\n"
	fi
fi
sleep 1
echo 7 > /proc/sys/kernel/printk

