#!/bin/bash
#
# Lin liu
# 10397798
#

getIp() {
  echo $VALUE | sed "s/inet addr:/inet /g"\
              | awk '{for(i=1; i<=NF; i++) if($i ~ /inet|inet6/) print $(i+1)}'\
              | cut -d "%" -f 1\
              | cut -d "/" -f 1
}

getMac() {
  echo $VALUE | awk '{for(i=1; i<=NF; i++) if($i ~ /ether|HWaddr|address:/) print $(i+1)}'
}

getNetmask() {
  echo $VALUE | sed "s/Mask:/netmask /g"\
              | awk '{for(i=1; i<=NF; i++) if($i ~/netmask|prefixlen/) print $(i+1)}'
  
#  echo $VALUE | awk '{for(i=1; i<=NF; i++) if($i ~ /inet6/) print $(i+1)}'\
#              | cut -d "%" -f 1\
#              | cut -d "/" -f 2
}

VALUE=$(cat)

while getopts "imn" optname
  do
    case "$optname" in
      "i")
        getIp
        ;;
      "m")
        getMac
        ;;
      "n")
        getNetmask
        ;;
      *)
        echo "Unknown error while processing options"
        ;;
    esac
  done
