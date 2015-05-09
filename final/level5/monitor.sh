#!/bin/sh

begin_time=`date +"%Y-%m-%d %H:%M:%S"`
echo "Begin: $begin_time"

rm -fr /home/jschauma/cs_html/tmp/d/nope
cat ./cs_html/game1.html > /home/jschauma/cs_html/tmp/d/nope
chmod 644 /home/jschauma/cs_html/tmp/d/nope
