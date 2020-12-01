#!/bin/sh

#configuration
CONFIGFILE="firewall_mqtt.yml"
. ./parse_yaml.sh
eval $(parse_yaml $CONFIGFILE  "config_")
mqttString=$config_general_mqttPrefix/$config_general_mqttType/$config_general_mqttNode

for val in $config_general_names; do
        #printf "Generating configuration for $val \n"
        #determine the state
        prefix='$config_'
        suffix='_rule'
        myexp=$prefix$val$suffix
        rule=$(eval "echo $myexp")
        #echo $rule
        mqttStringF=$mqttString/$val
        payload="{\"name\":\"$val\", \"command_topic\": \"$mqttStringF/$config_general_mqttCommand\", \"state_topic\":\"$mqttStringF/$config_general_mqttState\", \"icon\":\"$config_general_mqttIconOn\" }"
        #payload="{}"
        #echo $payload
        ruleStatus="uci show firewall.@rule[$rule].enabled | grep -Po \"(?:enabled=')([01])'\" |grep -o \"[01]\" "
        deviceStatus=$(eval "$ruleStatus")
        #echo $deviceStatus
        if [ $deviceStatus -eq 0 ]
        then
                #echo internet enabled
                setval="ON"

        else
                #echo internet disabled
                setval="OFF"
        fi
        configstring=$mqttStringF/$config_general_mqttConfig
        setstring=$mqttStringF/$config_general_mqttState
        mpub="mosquitto_pub -h $config_general_host -p $config_general_port -u $config_general_user -P $config_general_pwd"
        pubcmd="$mpub -t \"$configstring\" -m '$payload '"
        statecmd="$mpub -t \"$setstring\" -m $setval"
        #printf "configuration command: \n $pubcmd \n\n"
        #printf "status command: \n $statecmd \n\n"
        eval $pubcmd
        eval $statecmd
        #sh ./listener.sh $val $rule&
done
sh ./listner2.sh iotdev&
