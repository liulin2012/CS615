#CS615-HW3

##How to use

This script can extract all IP addresses,all MAC addresses,all netmasks
use the command `ifconfig -a | ./ifcfg-data.sh -[imn]` or `ifconfig -a | sh ./ifcfg-data.sh -[imn]`,it depends on the linux distribution

##The main idea

I have used the `awk` to find some words such as `inet` `ether` that will append what I want in the next word
Then I will take the next word.

In some platform ,I need to use `sed` to transfer the word to what I want,such as `Mask:` to the `netmask `
I also use the `cut` to filter the the data
