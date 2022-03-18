Instructies
-----------

1. Configuratie: edit `launch.sh` om de server aan te passen, in `peilbot.awk` de functie `trusted()` aanpassen met de criteria om de admin te herkennen als je niet het challenge/response systeem wil gebruiken.

2. Uitvoeren: `launch.sh [BOTNAAM] [DEADLINE]`, met DEADLINE iets dat AWK's `mktime()` accepteert, of "+n" voor "n minuten in de toekomst".

3. Beheren: 
   * Public: "optie1->optie2" om keuzes samen te voegen (of te laten verdwijnen als optie2 niet bestaat). Dit is reversibel.
   * Private: !EXTEND <minuten>, !JOIN <channel>, !PART <channel>, !DIE, !QUOTE <raw irc command>
