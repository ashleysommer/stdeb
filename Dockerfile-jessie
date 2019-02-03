FROM debian:jessie

RUN apt-get update
RUN apt-get install -y git bash python3-dev python3-all-dev python3-pip python3-setuptools python3-requests apt-file\
 dpkg-dev debhelper dh-python dh-autoreconf dh-strip-nondeterminism build-essential autotools-dev fakeroot gnupg2 curl

RUN curl "http://http.us.debian.org/debian/pool/main/d/debhelper/debhelper_10.2.5~bpo8+1_all.deb" -o debhelper_10.2.5~bpo8+1_all.deb
RUN curl "http://http.us.debian.org/debian/pool/main/d/dh-autoreconf/dh-autoreconf_12~bpo8+1_all.deb"  -o dh-autoreconf_12~bpo8+1_all.deb
RUN curl "http://http.us.debian.org/debian/pool/main/s/strip-nondeterminism/dh-strip-nondeterminism_0.034-1~bpo8+1_all.deb" -o dh-strip-nondeterminism_0.034-1~bpo8+1_all.deb
RUN curl "http://http.us.debian.org/debian/pool/main/s/strip-nondeterminism/libfile-stripnondeterminism-perl_0.034-1~bpo8+1_all.deb" -o libfile-stripnondeterminism-perl_0.034-1~bpo8+1_all.deb
RUN curl "http://http.us.debian.org/debian/pool/main/d/dh-python/dh-python_2.20170125~bpo8+1_all.deb" -o dh-python_2.20170125~bpo8+1_all.deb
RUN dpkg --install debhelper_10.2.5~bpo8+1_all.deb dh-autoreconf_12~bpo8+1_all.deb libfile-stripnondeterminism-perl_0.034-1~bpo8+1_all.deb dh-strip-nondeterminism_0.034-1~bpo8+1_all.deb dh-python_2.20170125~bpo8+1_all.deb


RUN pip3 install "stdeb3>=0.9.0"

RUN useradd -m -U stdeb3

WORKDIR /home/stdeb3

ADD ./docker-script.sh /home/stdeb3/

ENV PYTHON_PROJECT_GIT="https://github.com/ashleysommer/stdeb3.git"
ENV PYTHON_PROJECT_BRANCH="master"
ENV GPG_SECRET_KEY=""
ENV GPG_SECRET_KEY_PASSPHRASE=""
ENV PRESERVE_OUTPUT_VOLUME=""
ENV STDEB3_SOURCE_ONLY=""
ENV STDEB3_EXTRA_ARGS=""
ENV STDEB3_SIGN_RESULTS=""
ENV STDEB3_SIGN_KEY=""

VOLUME /home/stdeb3/output
USER stdeb3
CMD ["bash", "/home/stdeb3/docker-script.sh"]