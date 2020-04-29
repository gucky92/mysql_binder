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
        git \
        default-mysql-client \
        libmcrypt-dev && \
    curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install default-mysql-server
# RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
#        nodejs \
#        npm
# RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server


# Create user with a home directory
ARG NB_USER
ARG NB_UID
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

# COPY add_user.sql ${HOME}/add_user.sql
# RUN chown -R ${NB_UID} ${HOME}

WORKDIR ${HOME}

ADD . ${HOME}

# Download and install the MySQL example employees database
# c.f. https://github.com/datacharmer/test_db
RUN printf "\n### Start MySQL server\n### /etc/init.d/mysql start\n" && \
    /etc/init.d/mysql start && \
    cd ${HOME} && \
    printf "\n### Add jovyan as MySQL user\n### mysql -u root < add_user.sql\n" && \
    mysql -u root < add_user.sql && \
    echo "${USER} ALL=/sbin//etc/init.d/mysql start" >> /etc/sudoers && \
    echo "${USER} ALL=/sbin//etc/init.d/mysql stop" >> /etc/sudoers && \
    echo "${USER} ALL=/sbin//etc/init.d/mysql restart" >> /etc/sudoers

# Install the notebook package and install jupyterlab-sql extension
RUN pip install --no-cache --upgrade pip && \
    pip install --no-cache notebook && \
    pip install git+https://github.com/gucky92/datajoint-python.git && \
    pip install seaborn && \
    pip install scikit-learn
# RUN pip install --no-cache --upgrade pip setuptools wheel && \
#    pip install --no-cache notebook && \
#    pip install --upgrade --no-cache -e .
# RUN jupyter serverextension enable jupyterlab_sql --py --sys-prefix && \
#    jupyter lab build

USER ${USER}
