# openwrtfw-ha
Integrates OpenWRT firewall with HomeAssistant via MQTT

This is a project in alpha stage. Use at your own risk. 

My main goal was to be able to restrict internet access to my 4 year old child on his tablet and on our Roku. 
OpenWRT has parental controls but they need to be activated by set times which was not working for us. I was logging in into openWRT and activating/deactivating the rules manually. Needless to say, the setup was not intuitive and my wife was not willing to learn it.


I took inspiration in the following tutorial:
https://medium.com/@arturlr/using-iot-button-to-control-my-kids-internet-usage-5bd825c1da76

I did not feel particulary inspired to buy an Amazon IOT device, keep batteries for it. In addition, by using iptables directly it breaks the LUCI firewall status display. It is not persistent, and a reboot of the router will revert to the default configuration with no visual feedback of the firewall status. 

So I decided to use a software switch, one provided by HomeAssistant. I already have a dashboard where I control lights. I could make a dashboard for controlling the activation/deactivation of firework rules; and will provide visual feedback of the rule status. Individual dashboards can be assigned for determined users which should log in to the system. So potentially in a few years I could give him access to the lighting system and still preserve my internet authority. For the future I am thinking of getting a pin device for his room (https://ezzwave.com/ge-z-wave-plus-hinge-pin-smart-door-sensor) and just allow his internet to be active when the door is open (I guess after 13-14 years old, there is no more point in being the internet control tzar)

For this project I am using un-encrypted mqtt and the firewall rules are based on MAC Addresses. I guess that if he uses wireshark to sniff the MQTT messages or is able to spoof his MAC Address he will be able to overcome the system. I am not expecting him to develop those skill yet and if he does, he will have earned his access.

## Other Uses
- allow/disallow a port forward
   * access to a webserver/ftp server just when you need it.
- turn on/off a DMZ 
- block your IOT devices from the internet but have an easy way to re-connect them for OTA upgrades
- with some modifications may allow to report your connectivity to HA.. external IP address, connection speed, etc. 


# Requirements
OpenWRT - I am using OpenWrt 19.07.2 r10947-65030d81f3 

HomeAssistant with configured mosquitto broker and working mqtt integration (you could also run mosquitto broker on openwrt and have HomeAssistant connect to it)

# Install dependencies
opkg update

opkg install mosquitto mosquitto-client libmosquitto grep

obtain parse_yaml.sh parser (https://gist.github.com/pkuczynski/8665367)

# Setup - OpenWRT
0. install depependencies using opkg as above
1. Configure the rules using LUCI or UCI
2. use the ssh interface to determine which rules you want to control. Use the command "uci show firewall"
3. make a directory /etc/iot/
4. copy announcer.sh, listner2.sh, firewall_mqtt.yml, and parse_yaml.sh (see github link above) to your new directory
5. make the .sh files executable 
   - chmod +x announcer.sh
   - chmod +x listner2.sh
   - chmod +x parse_yaml.sh
6. modify the firewall_mqtt.yml file to your needs. 
7. Create startup script to execute announcer.sh upon device initiation. (working on it, will publish it when ready)

Once you have this, execute announcer.sh from the /etc/iot directory. If everything goes well, the script will announce itself to the mqtt broker. 

# Setup - HomeAssistant

HA will get the message and will create the proper entities. The entities will not appear as a "new integration". However, they will be available automatically. Just add a button card. The entity name will be switch.name, where name is the name you used in the firewall_mqtt.yml file. 

