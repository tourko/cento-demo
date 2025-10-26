# cat Dockerfile 
# syntax=docker/dockerfile:1.2
# check=error=true

FROM rockylinux:9
ADD https://packages.ntop.org/centos/ntop.repo /etc/yum.repos.d/ntop.repo
RUN dnf --assumeyes install epel-release
RUN dnf config-manager --set-enabled crb

RUN dnf --assumeyes clean all
RUN dnf --assumeyes update
RUN dnf --assumeyes install ncurses file
RUN dnf --assumeyes install cento
RUN dnf --assumeyes clean all

RUN echo "/opt/napatech3/lib" > /etc/ld.so.conf.d/napatech3.conf

ARG PFRING_SN=000-0000-00-00-0000-000000
RUN mkdir -p /etc/pf_ring/
ADD licenses/pf_ring.license /etc/pf_ring/$PFRING_SN
ADD licenses/cento.license /etc/cento.license

RUN mkdir /opt/cento
RUN mkdir /opt/cento/ntpl
RUN mkdir /opt/cento/scripts

ADD ntpl/*.ntpl /opt/cento/ntpl

ADD scripts/common.sh /opt/cento/scripts
ADD scripts/apply_ntpl.sh /opt/cento/scripts
ADD scripts/run_cento_bridge.sh /opt/cento/scripts
ADD scripts/run.sh /opt/cento/scripts
RUN chmod +x /opt/cento/scripts/run.sh

WORKDIR /opt/cento

ENTRYPOINT ["/opt/cento/scripts/run.sh"]
