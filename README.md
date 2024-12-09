# blastion_ssh
A high interaction SSH honeypot using bash and openssh edited versions.  
On github, you will only have edited files, but on the honeypot itself, you will get every commands and every login tries done.

[Here](https://hub.docker.com/r/unbonwhisky/blastion_ssh) is the link to the Docker Hub page

## WARNING

Be sure to block SSH from the honeypot to the host to avoid escalation and make sure to change the SSH port in your server.

### Block SSH from the honeypot to the server :
It can be done using this command :  
```
sudo iptables -A INPUT -p tcp -s <container IP or network> --dport 22 -j DROP
```
Or by including this part in your `/etc/ssh/sshd_config` file : 
```
Match Address <container IP or network>
    PasswordAuthentication no
    PubkeyAuthentication no
    PermitRootLogin no
```

Finally, restart the ssh server.  
Example : `systemctl restart ssh`

### Change SSH port of the server :
Edit the `/etc/ssh/sshd_config` and search for this line :
```
#Port 22
```

Change it to something else like this :
```
Port 2222
```

Finally, restart the ssh server.  
Example : `systemctl restart ssh`

## Application Setup

Access the honeypot at `<your-ip>:22`.

## Usage

To help you get started creating a container from this image you can use docker-compose.

### docker-compose (recommended)

```yaml
version: "3.7"
services:
  blastion:
    container_name: blastion_ssh
    cap_add:
      - LINUX_IMMUTABLE
    environment:
      #- Example :
      # - USERNAME=ubuntu
      # - PASSWORD=ubuntu
      - USERNAME=<username you want to use for the login to container ssh>
      - PASSWORD=<password you want to use for the login to container ssh>
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Paris
    image: unbonwhisky/blastion_ssh:latest
    hostname: <hostname you want for the honeypot in SSH>
    ports:
      - 22:22
    restart: unless-stopped
    volumes:
      - "/path/to/container/homedir:/home/<username you have set on top>"
```

## Contributors
This project have been made with [@Marokingu](https://github.com/Marokingu) and [@alexilrx](https://github.com/alexilrx)
