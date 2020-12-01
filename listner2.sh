#!/bin/sh

#configuration
CONFIGFILE="firewall_mqtt.yml"
. ./parse_yaml.sh
eval $(parse_yaml $CONFIGFILE  "config_")
mqttString=$config_general_mqttPrefix/$config_general_mqttType/$config_general_mqttNode
mqttStringF=$mqttString/+
monitorcmd="mosquitto_sub -h $config_general_host -p $config_general_port -u $config_general_user -P $config_general_pwd -q 1 -t \"$mqttStringF/$config_general_mqttCommand\" -v "
mpub="mosquitto_pub -h $config_general_host -p $config_general_port -u $config_general_user -P $config_general_pwd"
prefix='$config_'
suffix='_rule'
mexp="("
for val in $config_general_names; do
        mexp="$mexp($val)|"
done
mexp="$mexp)"


p="$1"
([ ! -p "$p" ]) && mkfifo $p
(eval $monitorcmd >$p 2>/dev/null) & PID=$!

trap 'kill $PID' HUP INT TERM QUIT KILL

while read line <$p
do
   #echo $line
   entity=$(echo $line | grep -o -P $mexp)
   prerule=$prefix$entity$suffix
   rule=$(eval "echo $prerule")
   mycm=$(echo $line | grep -o -P '(ON|OFF)')
   #echo "just received a command for $entity which will affect rule $rule and the command is $mycm "
   setstring=$mqttString/$entity/$config_general_mqttState

   if [ "$mycm" = "ON" ]; then
      statecmd="$mpub -t \"$setstring\" -m ON"
      eval $statecmd
      #printf "changed homeassistant state to ON for $entity \n"
      uci set firewall.@rule[$rule].enabled=0
      #printf "changed firewall setting to enabled=0 for enity, rule $rule \n"
      fw3 reload &>/dev/null
      #printf "reloaded firewall \n"
   fi
   if [ "$mycm" = "OFF" ]; then
      statecmd="$mpub -t \"$setstring\" -m OFF"
      eval $statecmd
      #printf "changed homeassitant state to OFF for $entity \n"
      uci set firewall.@rule[$rule].enabled=1
      #printf "changed fireawll setting to entabled=1 for $entity, rule $rule \n"
      fw3 reload &>/dev/null
      #printf "reloaded firewall \n"
   fi
done
