function dump(what) {
	print "#", what > "/dev/stderr"
}

function shift () {
	$1=""; sub("^"FS,"")
}

function trusted() { #feel free to hardcode the ADMINPREFIX
	return ADMINPREFIX && PREFIX == ADMINPREFIX
}

function mentioned() {
	return $3 ~ "^" COLON IDENTITY":"
}

function tell(who,msg) {
	if(block[who] > 5) return
	tick=sprintf("%d",systime()/10) % 2
	if(flood[who, tick]++ > 2) {
		block[who]++
		dump("ANTI-FLOOD " who)
	} else {
		delete flood[who, 1-tick]
		print "PRIVMSG", who, COLON ferrymingelen(msg)
	}
}

# put the IRC protocol prefix in separate var
PREFIX=""
$1~/^:/ {
	PREFIX=$1
	sub("^"COLON, "", PREFIX)
	shift()
}

BEGIN {
	"openssl rand -base64 6" | getline NONCE
	TIMEFMT="%d-%m-%Y, %H:%M %Z"
	if(!IDENTITY)  IDENTITY="PeilBot"
	if(!THRESHOLD) THRESHOLD=2
	if(!DEADLINE)  {
		DEADLINE=systime()+24*60*60;
	} else if(DEADLINE ~ /^\+/) {
		DEADLINE=systime()+DEADLINE*60;
	} else {
		gsub(/[-.]/, " ", DEADLINE)
		DEADLINE=mktime(DEADLINE " 00 00 00")
	}
	FS=OFS=" "
	COLON=":"
	print "USER", IDENTITY, "*", "*", COLON IDENTITY
	print "NICK", IDENTITY
	RPL_ENDOFMOTD=376
}

$1=="PING" {
	print "PONG", $2
}

$1=="PRIVMSG" && $2==IDENTITY && $3~"^:!" && trusted() {
	sub("^:!", "", $3)
	shift(); shift()
	dump("ADMIN: " $0)
	if(toupper($1)=="QUOTE") {
		shift()
		command=$0
		print command
	} else if(toupper($1)=="JOIN") {
		print "JOIN", $2
		tell($2, advertisement())
	} else if(toupper($1)=="PART") {
		print "PART", $2, COLON tally()
	} else if(toupper($1)=="EXTEND") {
		DEADLINE = systime() + $2*60
	} else if(toupper($1)=="DIE") {
		THRESHOLD=0
		DEADLINE=systime()
		print "QUIT", COLON tally()
	}
	next
}

$1=="PRIVMSG" && (mentioned() || $2==IDENTITY) && split(PREFIX, user, "!") {
	account=PREFIX
	nick   =user[1]
	outlet =($2!=IDENTITY? $2 : nick)
	sub(/.*:/,"", $3)
	shift(); shift()
	sub(/ *$/, "", $0)
	msg=toupper($0)
	act=toupper($1)
	if($1 == NONCE && !ADMINPREFIX) {
		ADMINPREFIX = PREFIX
		dump("AUTHENTICATED: "ADMINPREFIX)
		tell(nick, "ACK.")
	} else if(act == "HELP") {
		tell(outlet, "zeg tegen mij op wat je hebt gestemd (\"/msg " IDENTITY " <keuze>\" of publiek \"" IDENTITY ": <keuze>)\"")
	} else if(act == "UITSLAG") {
		if(outlet == nick) {
			tell(nick, "Om de uitslag vragen kan alleen in een publiek kanaal.")
		} else {
			tell(outlet, tally())
		}
	} else if(trusted() && act ~ /->/) {
		split(act, mkalias, / *-> */)
		if(mkalias[1]==mkalias[2]) delete alias[mkalias[1]]
		else alias[mkalias[1]]=mkalias[2]
		tell(outlet, tally())
	} else if(act ~ /->/) {
		tell(nick, "helaas pindakaas")
	} else if(has_voted[account]) {
		tell(nick, "Je mag maar één keer stemmen")
	} else if(systime() >= DEADLINE) {
		tell(outlet, "De peiling is voorbij.")
	} else {
		has_voted[account]++
		num_votes[msg]++
		dump("*****************")
		dump("* VOTE RECORDED *")
		dump("*****************")
		tell(nick, "Je keuze voor " act " is verwerkt; je mag nu vragen om de \"UITSLAG\".")
	}
	next
}

$1!="PRIVMSG" {
	dump(COLON PREFIX " " $0)
}

$1==RPL_ENDOFMOTD {
	dump("DEADLINE: "strftime(TIMEFMT, DEADLINE))
	dump("ONE-TIME-AUTHENTICATION PHRASE: "NONCE)
}

function advertisement() {
	return "Ledenpeiling! Stemmen kan tot " strftime(TIMEFMT, DEADLINE) " precies."
}

function tally() {
	total_votes=0
	for(party in num_votes) {
		total_votes+=num_votes[party]
	}
	if(total_votes <= THRESHOLD) {
		return "Er zijn niet genoeg deelnemers aan de peiling."
	} else if(systime() < DEADLINE) {
		remain=DEADLINE-systime()
		return "De uitslag is er over " (remain>3600? sprintf("%d uur", remain/3600) : remain>120? sprintf("%d minuten", remain/60) : sprintf("%d seconden", remain))
	} else {
		result=""
		for(party in num_votes) {
			if(party in alias)
				;
			else {
				votes=num_votes[party]
				for(altname in alias) {
					if(alias[altname]==party) votes+=num_votes[altname]
				}
				result=result "; " sprintf("%s: %.1f%%", party, 100*votes/total_votes)
			}
		}
		sub("^; ", "", result)
		DEADLINE = systime() + EXTENDEDVOTING*60
		return result
	}
}

function ferrymingelen(str) {
        split(str, words)
        str=words[1]
        for(i=2; i <= length(words); i++) {
                str = str (rand() >= 0.8? " ... " : " ") words[i]
	}
        return str
}
