# blastion_ssh
A high interaction SSH honeypot using bash and openssh edited versions.  
On github, you will only have edited files, but on the honeypot itself, you will get every commands and every login tries done.

## WARNING

Be sure to block SSH from the honeypot to the host to avoid escalation.

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
