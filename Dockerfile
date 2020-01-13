#
# This file is part of Viper - https://github.com/viper-framework/viper
# See the file 'LICENSE' for copying permission.
#

FROM ubuntu:bionic
MAINTAINER Viper-Framework (https://github.com/viper-framework)

ENV YARA_VERSION       3.10.0
ENV ANDROGUARD_VERSION       3.3.5
ENV PIP_NO_CACHE_DIR off
ENV PIP_DISABLE_PIP_VERSION_CHECK on
ENV DEBIAN_FRONTEND noninteractive

USER root
RUN apt-get -qq update && \
    apt-get install -y -qq \
    git \
    gcc \
    python3-dev \
    python3-pip \
    python-pip \
    bison  \
    automake \
    make \
    curl \
    wget \
    libtool \
    autoconf \
    flex \
    libffi-dev \
    ssdeep \
    libfuzzy-dev \
    unrar \
    p7zip-full \
    swig \
    libssl-dev \
    vim-tiny \
    crudini \
    radare2 \
    clamav-daemon \
    autopoint \
    libtool \
    pkg-config \
    unzip \
    python-setuptools \
    supervisor \
    upx \
    postgresql \
    postgresql-server-dev-all \
    libcrypt-rc4-perl \
    libdigest-crc-perl \
    libcrypt-blowfish-perl \
    libole-storage-lite-perl \
    libimage-exiftool-perl && \
  rm -rf /var/lib/apt/lists/*

# Make Tmp Dir
RUN mkdir ~/tmp_build


RUN cd ~/tmp_build && \
  curl -sSL https://github.com/androguard/androguard/archive/v${ANDROGUARD_VERSION}.tar.gz | \
  tar -xzC .  && \
  cd androguard-${ANDROGUARD_VERSION} && \
  python3 setup.py install


# Install Yara
RUN cd ~/tmp_build && \
  git clone -b v${YARA_VERSION} https://github.com/VirusTotal/yara && \
  cd yara && \
  bash bootstrap.sh && \
  ./configure --enable-dex --enable-magic --enable-dotnet --enable-macho && \
  make install && \
  cd .. && \
  rm -rf yara && \
  ldconfig

RUN pip3 install --upgrade yara-python psycopg2


# Create Viper User
RUN groupadd -r viper && \
  useradd -r -g viper -d /home/viper -s /sbin/nologin -c "Viper User" viper && \
  mkdir /home/viper && \
  chown -R viper:viper /home/viper

# Clean tmp_build

RUN wget -q -O ~/tmp_build/vt-cli.zip https://github.com/VirusTotal/vt-cli/releases/download/0.6.1/Linux64.zip && \
	unzip -d /usr/local/bin ~/tmp_build/vt-cli.zip && \
	mv /usr/local/bin/vt /usr/local/bin/vt2


RUN git clone https://github.com/doomedraven/VirusTotalApi ~/tmp_build/virustotal && \
        cd ~/tmp_build/virustotal && \
        python setup.py install

RUN wget -O /usr/local/bin/DeXRAY.pl http://hexacorn.com/d/DeXRAY.pl && \
        chmod 755 /usr/local/bin/DeXRAY.pl

USER viper
WORKDIR /home/viper
RUN git clone https://github.com/viper-framework/viper && \
  mkdir /home/viper/workdir

RUN cd /home/viper/viper/viper/modules/ && \
        git clone https://github.com/viper-framework/pdftools

RUN git clone https://github.com/Neo23x0/signature-base /home/viper/.viper/yara/signature-base && \
        mkdir -p /home/viper/.viper/yara/iddqd/ && \
        curl -s  -o  /home/viper/.viper/yara/iddqd/iddqd.yar https://gist.githubusercontent.com/Neo23x0/f1bb645a4f715cb499150c5a14d82b44/raw/bb6235c3770c2a5301dbb03b9604510766a2a25e/iddqd.yar && \
        git clone https://github.com/Yara-Rules/rules  /home/viper/.viper/yara/yara-rules && \
        rm -rf /home/viper/.viper/yara/yara-rules/Mobile_Malware && \
        rm /home/viper/.viper/yara/yara-rules/*yar && \
		git clone https://github.com/InQuest/yara-rules /home/viper/.viper/yara/inquest


USER root
WORKDIR /home/viper/viper
RUN pip3 install -r requirements.txt


RUN git clone https://github.com/libyal/libpff.git ~/tmp_build/libpff  && \
        cd ~/tmp_build/libpff/ && \
        ./synclibs.sh && \
        ./autogen.sh && \
        ./configure && \
        make all install

RUN pip install -U https://github.com/decalage2/ViperMonkey/archive/master.zip


RUN ldconfig


RUN rm -rf ~/tmp_build

COPY supervisord.conf /etc/supervisor/conf.d/viper.conf

RUN crudini  --set /etc/postgresql/10/main/postgresql.conf '' idle_in_transaction_session_timeout 0
RUN crudini  --set /etc/postgresql/10/main/postgresql.conf '' max_connections 1024
RUN crudini  --set /etc/postgresql/10/main/postgresql.conf '' max_connections 1024
RUN cp /home/viper/viper/viper.conf.sample /home/viper/.viper/viper.conf
#RUN crudini --set --existing /home/viper/.viper/viper.conf database connection  postgresql://viper:viper@localhost:5432/viper
RUN crudini  --set --existing /home/viper/.viper/viper.conf autorun commands "yara scan -t, fuzzy, pe compiletime, clamav -t, exif, shellcode"



RUN mkdir -p /var/run/clamav && \
    chown -R clamav /var/run/clamav


ADD firstboot.sh /firstboot.sh
ADD firstboot.sql /firstboot.sql
RUN touch /firstboot.tmp

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

#USER viper
#WORKDIR /home/viper/viper
#ENTRYPOINT ["../viper/viper-cli"]
