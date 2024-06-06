#! /bin/sh
SERVER=irc.libera.chat:6697
ulimit -Sv 50000
socat OPENSSL:"$SERVER",pf=ip6,crnl EXEC:"mawk -f peilbot.awk -v IDENTITY=${1:-PeilBot} -v DEADLINE=\\\"$2\\\"",pty,echo=0
