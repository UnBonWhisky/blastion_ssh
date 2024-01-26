#!/bin/bash

# $1 : username (default : ubuntu)
# $2 : password (default : debian)
# $3 : UID (default : 1000)
# $4 : GID (default : 1000)
# $5 : timezone

# > /dev/null 2>&1 : sert à éviter d'obtenir un output (même en cas d'erreur), qui pourrait être générées et affichées dans les logs du container

# Affichage de notre petit ascii art pour l'ouverture des logs. Simplement à but esthetique
ascii_art=$(cat << "EOF"
 ____  _           _   _                 ____ ____  _   _
| __ )| | __ _ ___| |_(_) ___  _ __     / ___/ ___|| | | |
|  _ \| |/ _` / __| __| |/ _ \| '_ \    \___ \___ \| |_| |
| |_) | | (_| \__ \ |_| | (_) | | | |    ___) |__) |  _  |
|____/|_|\__,_|___/\__|_|\___/|_| |_|___|____/____/|_| |_|
                                   |_____|
EOF
)
printf "%s\n" "$ascii_art"

# Vérification que tous les arguments sont bien présents
if [ -z "$1" ]; then
    echo "Error: Username must be specified as first argument."
    exit 1
fi

if [ -z "$2" ]; then
    echo "Error: Password must be specified as second argument."
    exit 1
fi

if [ -z "$3" ]; then
    echo "Error: UID must be specified as third argument."
    exit 1
fi

if [ -z "$4" ]; then
    echo "Error: GID must be specified as fourth argument."
    exit 1
fi

timezone=$5
if [ -z "$timezone" ]; then
    timezone="Europe/London"
fi

# On vérifie si le chattr a été effectué sur le fichier /var/log/auth.log pour éviter sa suppression
if [[ "$(lsattr /var/log/auth.log)" == *"-a-"*  ]]; then
    echo "Append_Only attribute already on /var/log/auth.log"
else
    chattr +a /var/log/auth.log
    echo "Append_Only attribute added to /var/log/auth.log"
fi

# On met un timezone pour la création du container, afin que le container soit à l'heure choisie
ln -fs /usr/share/zoneinfo/$timezone /etc/localtime > /dev/null 2>&1

# On retire les droits à tous les utilisateurs pour changer le mdp changer l'attribut immutable, ou encore pouvoir voir quels fichiers sont immutables
chmod 750 usr/bin/lsattr /usr/bin/chattr /usr/bin/passwd /usr/sbin/chpasswd > /dev/null 2>&1

# On supprime tous les home directory existants qu'il peut y avoir
rm -rf /home/* > /dev/null 2>&1

# Si on a un groupe avec le GID défini par $4 existant
if getent group $4 > /dev/null;
then

    # Si on a un utilisateur avec le UID défini par $3 existant
    if id -u $3 > /dev/null 2>&1;
    then

        # Modification du nom d'utilisateur en gardant l'UID défini par $3
        usermod -l $1 -d /home/$1 -m -g $1 -u $3 $1 > /dev/null 2>&1
        echo "Username changed to $1 with UID $3"

        # Modification du nom de groupe en gardant le GID défini par $4
        groupmod -n $1 -g $4 $1 > /dev/null 2>&1
        echo "Group changed to $1 with GID $4"

    else # Si on a pas de user avec le UID défini par $3

        # On crée l'utilisateur avec l'UID défini par $3
        useradd -rm -d /home/$1 -s /bin/bash -g $1 -u $3 $1 > /dev/null 2>&1
        echo "User $1 created with UID $3"

    fi

else # Si on a pas de groupe (donc pas d'utilisateur non plus)

    # Création du groupe au nom du user
    groupadd -g $4 $1 > /dev/null 2>&1
    echo "Group set to $1 with GID $4"

    # Création de l'utilisateur dans le système
    useradd -rm -d /home/$1 -s /bin/bash -g $1 -u $3 $1 > /dev/null 2>&1
    echo "User $1 created with UID $3"

fi

# On met le mot sur notre utilisateur
echo "$1:$2" | chpasswd
echo "Password ****** set"

# On copie les fichiers de base de profil qui sont ceux de /etc/skel/ vers le home
cp /etc/skel/.bash_logout /etc/skel/.bashrc /etc/skel/.profile /home/$1

# On place les bons droits sur tout le home directory à notre user
chown -R $3:$4 /home/$1

# Tous les fichiers qu'on retrouve dans le container qui ne sont pas des fichiers visibles sur un vrai serveur sont déplacés dans le /root/ pour le masquer
mv /etc/dpkg/dpkg.cfg.d/docker-apt-speedup /etc/apt/apt.conf.d/docker-autoremove-suggests /etc/apt/apt.conf.d/docker-disable-periodic-update /etc/apt/apt.conf.d/docker-no-languages /etc/apt/apt.conf.d/docker-clean /etc/apt/apt.conf.d/docker-gzip-indexes /.dockerenv /usr/share/vim/vim82/syntax/dockerfile.vim /root/ > /dev/null 2>&1
mv /usr/share/vim/vim82/ftplugin/dockerfile.vim /root/dockerfile.vim.otherone > /dev/null 2>&1

# Lancement de rsyslog pour sortir nos logs bash et sshd vers stdout / stderr
/usr/sbin/rsyslogd > /dev/null 2>&1

# Lancement du serveur SSH au premier plan, avec les logs retournant vers stderr à la place du syslog
/usr/sbin/sshd -4 &
tail -f -n0 /var/log/auth.log | grep --line-buffered -E '\[custom_bash\]|\[custom_sshd\]' | sed --unbuffered -E 's/^.*(\[custom_(bash|sshd)\])/\1/'
