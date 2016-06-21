## Verwendung



### Vorbereitung

- Man benötigt 2 Speichermedien:
    1. Das Boot-Medium mit dem LiveCD Image (sollte read-only sein, z.B. CD-ROM), und
    2. ein beschreibbares Medium, groß genug für ein Docker image und Arbeitsdateien. Empfohlene Größe 8GB oder mehr.
- Das Boot-Medium muss mit der live-CD ISO-Image bespielt werden (siehe README)
- Das beschreibbare Medium wird mit einem Linux Filesystem, z.B. ext4 formatiert. Um es erkennbar zu machen,
  wird im Wurzelverzeichnis eine leere Datei 'UseMe4DockerData' erstellt. Das kann zum Beispiel wie folgt
  gemacht werden. Zuerst stellt man den Device-PFad fest, etwa mit `tail dmesg` ngleich nachdem der USB flash drive 
  eingesteckt wird, oder mit `df -hT` wenn ein FAT-Filesystem vorhanden ist und gemountet wurde. Wenn das Medium
  unter /dev/sdb1 gelistet wird, kann es mit folgenden Befehlen im Terminal eingerichtet werden:
    
    mkfs.vfat /dev/sdb1
    mount /dev/sdb1  /mnt
    touch /mnt/UseMe4DockerData

- Um die erzeugten Dateien per Mail zu vershicken, muss man in der patool_config.json
  einen Mail-Account einrichten. Für Berechtigte gibt es einen vorkonfigurierten Account, der wie folgt
  eingerichtet werden kann:
   
    openssl enc -d -aes-256-cbc -in patool_config.json.enc -out patool_config.json

### Start
- Beide Medien und einen Smartcard Leser (PCSC) an den PC anstecken
- Vom Boot-Medium starten - dazu muss man meistens die Boot-Reiehenfolge im BIOS ändern
- Das System muss online sein, damit beim Start Updates eingespielt werden können
- Warten bis das System gestartet ist
- Beim ersten Start und im Fall eines Updates muss das Docker Image aus dem Netz geladen werden, die Größe beträgt rund 1GB.
- Die Bürgerkartenumgebung wird automatisch gestartet
- Das PVZD GUI wird automatisch gestartet.
- Wird das GUI beendet, wird auch der Docker Container beendet und gelöscht. Für einen Neustart wäre 
  auf der Commandline `/usr/local/bin/startall_user.sh` auszuführen.

### Funktionen für den Depositar
- Über das Terminal werden weitere Funktionen angeboten:
    
    cd /opt/PVZDpolman/PolicyManager/bin/
    # Zertifikate verwalten
    ./PAtool.sh --help 
    # Policy Management Point verwalten (PV-Teilnehmer und ihre Domänen, Portal-Admins)
    ./PMP.sh --help
        
### Sonstiges

Um Daten auch per Datenträger einlesen zu können kann ein Windows-kompatibler Datenträger helfen. Um
eine 2. Partition auf dem Docker-USB Drive einzurichten, würde man bei einem 16GB-Stick z.B. wie folgt vorgehen:

    # mit dmesg die Geräteadresse ermitteln, z.B. /dev/sdb
    sudo fdisk /dev/sdb
    # 2 primäre Partitionen erstellen, 13G + Rest (ca. 2,5G)
    sudo mkfs.ext4 -L dockerdata /dev/sdb1
    sudo mkfs.vfat -F 32 -n pvzddata /dev/sdb2