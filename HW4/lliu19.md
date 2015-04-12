#Traceroute
##lin liu 10397798

##Research
Nowadays,the internet is the network of network.Every network is an autonomous systems which connected to other autonomous systems throught the BGP routing.On the other hand,there are different level ISP to provide the service connect to the network.The largest is Tier-1 ISP.Every Tier-1 ISP need to connect to other Tier-1 ISP in order to transfer the data globally.Then reginal ISP access to the Tier-1 ISP so that they can access to the network in this Tier-1 ISP.Therefore, there are several relationship between those network.

* Transit (or pay) – The network operator pays money (or settlement) to another network for Internet access (or transit).
* Peer (or swap) – Two networks exchange traffic between their users freely, and for mutual benefit.
* Customer (or sell) – A network pays another network money to be provided with Internet access.

So if one network want to reach any other network on the internet,it must either:

* Sell transit (or Internet access) service to that network (making them a 'customer'),
* Peer directly with that network, or with a network who sells transit service to that network, or
* Pay another network for transit service, where that other network must in turn also sell, peer, or pay for access.

So if I want send a packet from my network to another network,the packet may go through many ISPs  including the Tier-1 ISP,reginal ISP etc.

##Example
**www.uni-marburg.de**
In this example,the packets need reach to Germany, so it should go through the submarine cables,but in this figure,it appear to "jump" from the country to the next continent.It reach to Europe directly from Colorado,not through the submarine cables.
![](http://i.imgur.com/f6slFEI.png)

The reason I think is in these three steps
5. Level3.net
6. Unknown
7. Level3.net

The packets access to the [Level 3 Communications](http://en.wikipedia.org/wiki/Level_3_Communications) which operates a Tier 1 network.It can access to any other Tier 1 network.On the other hand,I have checked that the Level3 has its own submarine cables between America and Europe.This is the [map website](http://maps.level3.com/default/#.VSq9GBPF8sA) 
![](http://i.imgur.com/v8fcpnU.png)

So,the packets access to the level 3 network and reach Europe through submarine cables,but the level 3 router didn't show on the map,so it appears to "jump" to Europe.

##Reference
[Peering](http://en.wikipedia.org/wiki/Peering)
[Level 3 Communications](http://en.wikipedia.org/wiki/Level_3_Communications)
[level3](http://www.level3.com/en/)
Computer Networking A Top-Down Approach