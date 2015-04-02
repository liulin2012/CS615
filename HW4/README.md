#CS615-HW4
##lin liu 10397798

###1. Record the data
First,I use the `-w` to record the tcpdump data to the file `stevenslog.out`
```
sudo tcpdump -w stevenslog.out
```

Second,begin the `traceroute` program.Print the result on the screen and the file `stevensTRoutelog.out` using `tee` command
```
traceroute  www.stevens.edu | tee stevensTRoutelog.out
```

Third,analyse the result from the file to UDP and ICMP file seperately.
```
tcpdump -r stevenslog.out -n -v host www.stevens.edu > stevensUDP.out
tcpdump -r stevenslog.out -n -v icmp > stevensICMP.out
```

This is the final result file I need to analyse.
![](http://i.imgur.com/39f0SCl.png)

###2. Traceroute
In the traceroute log file:
 
* `traceroute` program will first analyse the ip address from the domain
the `64 hops max` mean the last udp packet max ttl is 64.The last udp packet will not go throught more than 64 routes.
```
traceroute: Warning: www.stevens.edu has multiple addresses; using 54.225.152.51
traceroute to mc-4471-1746286150.us-east-1.elb.amazonaws.com (54.225.152.51), 64 hops max, 52 byte packets
```

* Each udp packet with the same ttl will send three times,but the transfer time is not same becasue the complex network status.Such as in the first line ,the first packet is `4.176 ms` but the second one is longer `13.573 ms`.
Some ip address can translate to domain such as the second line  `gwa.cc.stevens.edu (155.246.151.37) `,some ip address can't
```
1  155.246.171.2 (155.246.171.2)  4.176 ms  13.573 ms  3.869 ms
2  gwa.cc.stevens.edu (155.246.151.37)  1.623 ms  10.248 ms  4.967 ms
```

* Some udp packet didn't receive the response.The `*` means the packet response didn't back.There are a lot of reasons lead to this problem such as some route can't response the ICMP back or some packet has been intercepted by firewall.
Another things happen in the line 18,in the same round 18,the ttl is same ,but there are three different ip address for the packets.It means the route is dynamic so the route path maybe change everytime the traceroute send the packets.Everytime the program send a udp packet ,the route path may be different. 
```
18  216.182.224.221 (216.182.224.221)  333.719 ms
    216.182.224.195 (216.182.224.195)  374.516 ms
    216.182.224.229 (216.182.224.229)  258.496 ms
19  * * *
20  216.182.224.223 (216.182.224.223)  443.582 ms * *
21  * * *
22  * * *
23  * * *
24  * * *
25  * * *
```



####3. UDP
In the UDP log file

The source and destination ip address is always same.The destination `54.225.152.51` is the `www.stevens.edu` ip address.It means the traceroute send the udp packet to the same destination ip address.Then it will route through the route protocal in the network according to the destination ip address.The traceroute program can't control it.

First there are three `ttl 1` packet sent to the network.When the route receive the packet which `ttl` is 1,It will discard the packet and then response a ICMP to the source ip.If the `ttl` is not 1 or zero,the route will minus 1 from the ttl value,so the `ttl` mean the max number of routes the packet can pass.Therefore the `ttl 1` packet will response the first route.The `ttl 2` response the second route.

Each packet has the different id number

The destination port is very large and will be plus 1 each packet.The large port number means the destination can't receive the packet successfully,so it will send another kind of ICMP back,which is different from the ICMP before.When the sender receive this ICMP,The program stop.
```
11:04:14.460037 IP (tos 0x0, ttl 1, id 50393, offset 0, flags [none], proto UDP (17), length 52)
    155.246.171.80.50392 > 54.225.152.51.33435: UDP, length 24
11:04:14.516666 IP (tos 0x0, ttl 1, id 50394, offset 0, flags [none], proto UDP (17), length 52)
    155.246.171.80.50392 > 54.225.152.51.33436: UDP, length 24
11:04:14.530246 IP (tos 0x0, ttl 1, id 50395, offset 0, flags [none], proto UDP (17), length 52)
    155.246.171.80.50392 > 54.225.152.51.33437: UDP, length 24
11:04:14.534155 IP (tos 0x0, ttl 2, id 50396, offset 0, flags [none], proto UDP (17), length 52)
    155.246.171.80.50392 > 54.225.152.51.33438: UDP, length 24
11:04:14.579112 IP (tos 0x0, ttl 2, id 50397, offset 0, flags [none], proto UDP (17), length 52)
    155.246.171.80.50392 > 54.225.152.51.33439: UDP, length 24
11:04:14.589372 IP (tos 0x0, ttl 2, id 50398, offset 0, flags [none], proto UDP (17), length 52)
    155.246.171.80.50392 > 54.225.152.51.33440: UDP, length 24
11:04:14.594356 IP (tos 0x0, ttl 3, id 50399, offset 0, flags [none], proto UDP (17), length 52)
```
####4. ICMP
In the ICMP file

The route send back the ICMP because the `ttl` is 1,the route discard the packet
The ICMP is `ICMP time exceeded in-transit`

```
11:04:14.463897 IP (tos 0x0, ttl 255, id 0, offset 0, flags [none], proto ICMP (1), length 56)
    155.246.171.2 > 155.246.171.80: ICMP time exceeded in-transit, length 36
	IP (tos 0x0, ttl 1, id 50393, offset 0, flags [none], proto UDP (17), length 52)
    155.246.171.80.50392 > 54.225.152.51.33435: UDP, length 24
11:04:14.530176 IP (tos 0x0, ttl 255, id 0, offset 0, flags [none], proto ICMP (1), length 56)
    155.246.171.2 > 155.246.171.80: ICMP time exceeded in-transit, length 36
	IP (tos 0x0, ttl 1, id 50394, offset 0, flags [none], proto UDP (17), length 52)
    155.246.171.80.50392 > 54.225.152.51.33436: UDP, length 24

```

If the traceroute program packet arrive to the distination,the ICMP looks like that
```
11:28:00.835273 IP 137.248.1.79 > 155.246.171.80: ICMP 137.248.1.79 udp port 33492 unreachable, length 60
11:28:01.346572 IP 137.248.1.79 > 155.246.171.80: ICMP 137.248.1.79 udp port 33493 unreachable, length 60
11:28:01.730624 IP 137.248.1.79 > 155.246.171.80: ICMP 137.248.1.79 udp port 33494 unreachable, length 60
```

It's `ICMP xxx.xxx.xxx.xxx udp port xxxxx unreachable` because the traceroute choose a large port number which the distination can't reach so the destination will send back the port unreachable ICMP.




### The Visual route

####1. www.uni-marburg.de

* Althought the first figure show the distance between the source and destination is very large.It go through 5162 mils.But it only go through 14 route while the another short distance path go through 13 routes.It means the number of routes the packets go through is not significantly related to the distance between the source and destination 
![](http://i.imgur.com/0i8Vezy.png)
![](http://i.imgur.com/Ezx9yqm.png)

* In the figure,these two ip address has the same network number,but they are in the different place.On the other hand,both these two route path go through `188.1.243.62`,but in the map,they also in the different place.Why the same ip address is in the different place?I think there are many different reason,first is **proxy server**.Maybe the program show the **proxy server** address.The second possible reason is that IP geolocation is unreliable.The database in use to achieve the location in most cast is only the ip block.So it only show the rought ip geographic location.
![](http://i.imgur.com/jVAqLUM.png)
![](http://i.imgur.com/FJKStEg.png)

####2. www.uba.ar

* In the first figure,it return the destination ip address,but the second one is not.I think the second program will stop if it didn't receive three response.So there are three stars in the second figure.But I have also run the traceroute in my laptop.It also can't show the result to the  www.uba.ar,so I think the first figure program only response the ip address of  www.uba.ar,not definitely use the traceroute program. 
![](http://i.imgur.com/VjSu9lI.png)
![](http://i.imgur.com/TaLZjxw.png)

####3. www.hawaii.edu

* When the address is  www.hawaii.edu,the last four route path is exactly same.
`66.192.250.206`
`74.202.119.11`
`205.166.205.47`
`128.171.64.187`
I think the reason why the four routes path is same is that hawaii is an island.It is so small that it only need to few routes on the island.I also guess that the network entrance path maybe only one which is 66.192.250.206 in America.I have done the test from Chinese traceroute program website,the result is same,the route path also go through these four route ip address.
![](http://i.imgur.com/5dPmnNW.png)
![](http://i.imgur.com/tK0z9AM.png)
![](http://i.imgur.com/sI71Z1I.png)

####4. www.hku.hk

* I don't know why everytime I do the test for this website,my browser will collapse.

####5. www.du.ac.in

The domain `www.du.ac.in` ip address is `14.139.45.148`.It's an indian ip address.
In this figure,The start ip address `107.170.234.253` locate in california,then it go to the Europe and go back to the Canada.
Finally,it go to the `static-Delhi-vsnl.net.in` which is same subnet with the ip address `14.139.45.148`
![](http://i.imgur.com/smP9gtX.png)

In this figure,it show the path is from Europe to America and then back to the Europe.Fianlly,it didn't find the destination.
![](http://i.imgur.com/t9v6TEj.png)

It's my traceroute output,the path is from the Canada to the London and then go to the `14.140.210.22.static-delhi-vsnl.net.in (14.140.210.22)` which is the same subnet with the `14.139.45.148`
![](http://i.imgur.com/ZnpcS7N.png)

I think the route path is so chaotic.The reason is the destination is so far away from the Europe and Ameraca.So the route path maybe not very efficient to the destination.It should go through the long distance to the destination.The route protocal doesn't work very well for this website.So the browse speed maybe very slow.

####6. www.usyd.edu.au

The route path transfer between the `113.197.xxx.xxx` and `202.158.xxx.xxx` twice in the last four route path.The `113.197` is class A ip address.So they are the same subnet.The `202` is the class C ip address,so they are not the same subnet.But the domain `www.usyd.edu.au` ip address is `129.78.5.11`.Therefore,the route first go to the `113` network and then go out,but it go inside the `113` network again althrough it have entered in this subnet before.It means that although the correct route path maybe in the subnet,the route protocal also let the path outside the subnet possibly.
![](http://i.imgur.com/nkBmbZ1.png)
![](http://i.imgur.com/DPhMDdX.png)

