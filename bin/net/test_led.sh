#!/bin/sh

echo 1 > /proc/sys/kernel/printk
if [[ $2 == *.log ]]; then
	LOGFILE=$2
	echo "file=$LOGFILE"
fi
TEST_NAME="[BT/WIFI LED] - [Test LED]"
TEST_PARAMS=$1
TEST_PROMPT_PRE="Check the LED"
TEST_PROMPT_POST="Did you see the LED Blink?"
function Test_Function
{	
	for((i=0;i<3;i++))
	do
		echo -e "w 5101" | ./bin/net/advled -p /dev/vpm
		sleep 1
		echo -e "w 5100" | ./bin/ent/advled -p /dev/vpm
		sleep 1
		echo -e "w 5301" | ./bin/net/advled -p /dev/vpm
		sleep 1
		echo -e "w 5300" | ./bin/net/advled -p /dev/vpm
	done
	
	echo -e "w 5300" | ./bin/ent/advled -p /dev/vpm
    echo -e "w 5100" | ./bin/net/advled -p /dev/vpm

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
			Test_Function $TEST_PARAMS >> /dev/null 2>&1
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
echo 7 > /proc/sys/kernel/printk
