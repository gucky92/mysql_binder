# Following from the minimal Binder Dockerfile example
# https://github.com/binder-examples/minimal-dockerfile

FROM python:3.7-slim
USER root

# Install mysql-server
# root user will have no/blank password
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get -y install \
        sudo \
        curl \
        build-essential \
        git && \
    curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
        nodejs \
        npm \
        mysql-server

# Create user with a home directory
ARG NB_USER
ARG NB_UID
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}
WORKDIR ${HOME}

ADD . ${HOME}

# Download and install the MySQL example employees database
# c.f. https://github.com/datacharmer/test_db
RUN git clone --depth 1 https://github.com/datacharmer/test_db.git datbases/test_db && \
    cd datbases/test_db && \
    printf "\n### Start MySQL server\n### /etc/init.d/mysql start\n" && \
    /etc/init.d/mysql start && \
    printf "\n### mysql -u root < employees.sql\n" && \
    mysql -u root < employees.sql && \
    cd ${HOME} && \
    printf "\n### Add jovyan as MySQL user\n### mysql -u root < binder/add_user.sql\n" && \
    mysql -u root < binder/add_user.sql && \
    echo "${USER} ALL=/sbin//etc/init.d/mysql start" >> /etc/sudoers && \
    echo "${USER} ALL=/sbin//etc/init.d/mysql stop" >> /etc/sudoers && \
    echo "${USER} ALL=/sbin//etc/init.d/mysql restart" >> /etc/sudoers

# Install the notebook package and install jupyterlab-sql extension
RUN pip install --no-cache --upgrade pip setuptools wheel && \
    pip install --no-cache notebook && \
    pip install --upgrade --no-cache -e .
RUN jupyter serverextension enable jupyterlab_sql --py --sys-prefix && \
    jupyter lab build

USER ${USER}
