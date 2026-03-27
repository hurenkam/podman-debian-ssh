FROM debian:trixie
MAINTAINER Mark Hurenkamp <mark.hurenkamp@xs4all>

# Based on https://github.com/j8r/dockerfiles/blob/master/systemd/debian/Dockerfile

ENV LC_ALL=C
ENV DEBIAN_FRONTEND=noninteractive

# install base packages
# systemd / ssh / vim / ip utils
RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y \
        systemd systemd-sysv \
        cron \
        anacron \
	openssh-server \
	vim \
	iproute2

# install minimum cockpit packages
# for system administration
##RUN apt-get update && apt-get install -y \
##	cockpit-bridge \
##	cockpit-ws \
##	cockpit-system

# Make sure that there's a place to put authorized_keys
RUN mkdir -p /root/.ssh


# clean-up after apt
RUN apt-get clean && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
    /var/log/alternatives.log \
    /var/log/apt/history.log \
    /var/log/apt/term.log \
    /var/log/dpkg.log


RUN cd /lib/systemd/system/sysinit.target.wants/ \
    && rm $(ls | grep -v systemd-tmpfiles-setup)

RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/* \
    /lib/systemd/system/plymouth* \
    /lib/systemd/system/systemd-update-utmp*


# Remove the machine's id, so that each container
# will generate a unique new id
RUN rm -f \
    /etc/machine-id \
    /var/lib/dbus/machine-id

RUN systemctl mask -- \
    dev-hugepages.mount \
    sys-fs-fuse-connections.mount

# copy overlay directories
COPY etc/ /etc/


# remove deleted files from intermediate layers
FROM debian:trixie
COPY --from=0 / /


# expose ssh port
EXPOSE 22

# expose cockpit port
##EXPOSE 9090

# configure systemd
ENV container docker
STOPSIGNAL SIGRTMIN+3

##VOLUME [ "/sys/fs/cgroup" ]
VOLUME [ "/sys/fs/cgroup", "/run", "/run/lock", "/tmp" ]

# start systemd
CMD [ "/sbin/init" ]

