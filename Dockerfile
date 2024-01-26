FROM ubuntu

ARG user=ubuntu
ARG pass=debian
ARG uid=1000
ARG gid=1000
ARG timezone=Europe/London
ENV USERNAME $user
ENV PASSWORD $pass
ENV PUID $uid
ENV PGID $gid
ENV TZ $timezone

COPY ./user_create.sh /root/
COPY openssh-8.9p1 /src/openssh-8.9p1
COPY bash-5.1 /src/bash-5.1

RUN sed -i -e 's/^# deb-src/deb-src/' /etc/apt/sources.list && \
    apt-get update && \
    apt-get upgrade --assume-yes && \ 
    DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --no-install-recommends tzdata && \
    apt-get build-dep --assume-yes openssh-server && \
    apt-get install -y --no-install-recommends libwrap0 ncurses-term && \
    apt-get install --assume-yes build-essential rsyslog locales fakeroot devscripts net-tools sudo nano vim iputils-ping curl libncurses-dev libreadline-dev && \
    adduser --system --group --disabled-password --disabled-login --home /var/run/sshd --no-create-home --gecos "OpenSSH Daemon" sshd && \
    locale-gen "en_US.UTF-8" && \
    sed -i '/imklog/s/^/#/' /etc/rsyslog.conf && \
    cd /src/openssh-8.9p1/ && \
    ./configure && \
    make install && \
    cd /src/bash-5.1/ && \
    ./configure && \
    make install && \
    mv /bin/bash /root/bash && \
    mv /usr/local/bin/bash /bin/bash && \
    chmod 755 /bin/bash && \
    apt-get install --assume-yes putty-tools python3-twisted && \
    mkdir /run/sshd && \
    mv /usr/local/sbin/sshd /usr/sbin/sshd && \
    touch /var/log/auth.log && \
    chown syslog:adm /var/log/auth.log && \
    chmod 640 /var/log/auth.log && \
    chmod 754 /usr/local/libexec/sftp-server && \
    cd && rm -rf /src && \
    apt-get clean && \
    apt-get autoremove --assume-yes && \
    chmod -R 600 /etc/ssh

# Ajout de la langue du clavier pour prendre en compte toutes les touches :
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Ouverture du port ssh
EXPOSE 22

# Lancement du script de création d'utilisateur basé sur les ENV ci-dessus
ENTRYPOINT [ "/bin/bash" , "-c" , "/root/user_create.sh $USERNAME $PASSWORD $PUID $PGID $TZ" ]
