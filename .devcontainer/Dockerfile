
ARG UBUNTU_VERSION=20.04
ARG SESUSER="robot"
ARG SESPASSWD="maker"

#========================================================================================================
# Build xrdp pulseaudio modules in builder container
# See https://github.com/neutrinolabs/pulseaudio-module-xrdp/wiki/README
#========================================================================================================


FROM ubuntu:$UBUNTU_VERSION as builder

RUN sed -i -E 's/^# deb-src /deb-src /g' /etc/apt/sources.list \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        build-essential \
        dpkg-dev \
        git \
        libpulse-dev \
        pulseaudio \
    && apt-get build-dep -y pulseaudio \
    && apt-get source pulseaudio \
    && rm -rf /var/lib/apt/lists/*

RUN cd /pulseaudio-$(pulseaudio --version | awk '{print $2}') \
    && ./configure

RUN git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git /pulseaudio-module-xrdp \
    && cd /pulseaudio-module-xrdp \
    && ./bootstrap \
    && ./configure PULSE_DIR=/pulseaudio-$(pulseaudio --version | awk '{print $2}') \
    && make \
    && make install

#========================================================================================================
# Build the final image
#========================================================================================================

FROM ubuntu:$UBUNTU_VERSION

# args uses in this stage
ARG SESUSER
ARG SESPASSWD

# Make persist in image
ENV LANG en_US.UTF-8
ENV SESUSER=$SESUSER
ENV SESPASSWD=$SESPASSWD
# note: ubuntu by default gives the user's group the same name as the user's name

# We used idea's from https://github.com/scottyhardy/docker-remote-desktop/ which installs xfce ; this image rather uses openbox
# Install xrdp with openbox window manager.
# Having a window manager next to gui app gives us some developer abilities in the image,
# so we also install extra's to have a more developer friendly environment.
#  - xterm/xdotool: to get a terminal and place the window fullscreen with xdotool ( see bin/xterm_custom) 
#  - vim/ne/less: to view/edit files
#  - htop: to see performance of processes
#  - mesa-utils: to test opengl
#  - sudo: to give user root rights; a window manager is run under a normal user account 
#  - envsubst: simple template tool (in gettext-base package)
#  - socat: to open localhost only service inside container to outside world so that we publish it on 
#           the dockerhost  localhost:port. The port becomes then internal on dockerhost.
#           We are basicly forwarding an internal container port  to and internal port on the docker host.
# - software-properties-common: to install add-apt-repository to allow adding other repositories
RUN apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        locales \
        xorgxrdp \
        xrdp \
        pulseaudio \
        pulseaudio-utils \
        sudo \
        x11-apps \
        mesa-utils \
        xterm \
        x11-xserver-utils \
        xdotool \
        openbox \
        vim \
        ne \
        less \
        htop \
        git \
        tree \
        rsync \
        gettext-base \
        socat \
        software-properties-common \
    && rm -rf /var/lib/apt/lists/*


#-----------------------------------------------------------------------------------------------------------------------------
# add SESUSER
#-----------------------------------------------------------------------------------------------------------------------------

# we use openbox window manager which is best run under a none-root user account

# Create the 'SESUSER' user account with sudo rights
RUN groupadd --gid 1020 $SESUSER
RUN useradd --shell /bin/bash --uid 1020 --gid 1020 --password $(openssl passwd $SESPASSWD) --create-home --home-dir /home/$SESUSER $SESUSER
RUN usermod -aG sudo $SESUSER

# create user's bin folder 
RUN mkdir -p /home/$SESUSER/bin
RUN chown -R $SESUSER:$SESUSER /home/$SESUSER/bin

#-----------------------------------------------------------------------------------------------------------------------------
# install scripts to run at container start and session login 
#-----------------------------------------------------------------------------------------------------------------------------

# entrypoint script starts xrdp sesman service and xrdp service on entrypoint of image; 
# as root run once at start of container  
COPY resources/scripts/entrypoint.sh /etc/xrdp/entrypoint.sh

# from entrypoint.sh we run as $SESUSER the script entrypoint_user.sh; 
# as $SESUSER run once at start of container  
# We use this to setup/run user specific things once at start of container.
# e.g. An user application can run a service listening only on a internal port. 
#      We can use this script to run a forward from an external port to an internal port used by a server listening only on an internal port.
#      With this forward inplace we can publish this service to docker host listening only on internal port on docker's host,
#      so we can connect to this application from outside the container on the docker's host!
COPY resources/scripts/entrypoint_user.sh /etc/xrdp/entrypoint_user.sh

# add custom xrdp session in startwm.sh (run with credentials of user who logs in) 
# run as user who logs in; run at every xrdp session, which can be multiple times in container lifetime
# - launches openbox 
# - setup environment for openbox: adds $HOME/bin to PATH 
#      instead setting PATH in $HOME/.bashrc we set it in the openbox gui environment 
#      in $HOME/.config/openbox/environment  
# - setup autostart config of openbox to launch a gui program (in $HOME/.config/openbox/autostart)
#   * only if bin/gui-program script exist will gui-program be launched when openbox starts
#   * only if bin/relaunch-gui-program script exists will the gui-program be automatically relaunched on exit (eg. when crashed)
COPY resources/scripts/startwm.sh /etc/xrdp/startwm.sh

#-----------------------------------------------------------------------------------------------------------------------------
# install pulseaudio support for xrdp  so that we have sound in our image over RDP
#-----------------------------------------------------------------------------------------------------------------------------

# autospawn pulse audio  
RUN sed -i -E 's/^; autospawn =.*/autospawn = yes/' /etc/pulse/client.conf \
    && [ -f /etc/pulse/client.conf.d/00-disable-autospawn.conf ] && sed -i -E 's/^(autospawn=.*)/# \1/' /etc/pulse/client.conf.d/00-disable-autospawn.conf || : \
    && locale-gen en_US.UTF-8

# copy pulse audio modules for xrdp from builder image to this image 
COPY --from=builder /usr/lib/pulse-*/modules/module-xrdp-sink.so /usr/lib/pulse-*/modules/module-xrdp-source.so /var/lib/xrdp-pulseaudio-installer/


# fix for broken audio after reconnecting a rdp session in /etc/xrdp/reconnectwm.sh
# see: https://github.com/scottyhardy/docker-remote-desktop/issues/32
RUN echo 'if ps -e -o cmd | grep "\[xrdp-chansrv\] <defunct>"; then DISPLAY=:10.0 /sbin/xrdp-chansrv & fi' >> /etc/xrdp/reconnectwm.sh

# add test file for sound : left_right.wav
# test in terminal with command:  
#      paplay ~/sound/left_right.wav 
RUN mkdir -p /home/$SESUSER/sound
COPY resources/sound/left_right.wav /home/$SESUSER/sound/left_right.wav



#-----------------------------------------------------------------------------------------------------------------------------
# update system python to be ready for development
#-----------------------------------------------------------------------------------------------------------------------------

# IMPORTANT
#
# NEVER develop in the system python environment itself, because it
# can break system packages dependent on the system python and its modules.
# That's the reason why we do not install python3-pip package.
# When doing something with the python distribution we must always use a venv:  
#     - for python projects use  a venv to make a sandbox environment within the project using its internal pip 
#     - to install python tools use pipx  to install a python tool in its own sandboxed venv
#
# For ubuntu 20.04 the system python is python3.8
#
# We install python3-venv and python3-dev packages so that we optionally 
# also can develop in the system's python3 in a VIRTUAL ENVIRONMENT! 
RUN sudo apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y  \
        python3-venv \
        python3-dev \
    && rm -rf /var/lib/apt/lists/*

#-----------------------------------------------------------------------------------------------------------------------------
#  Install pipx using system's python3.
#-----------------------------------------------------------------------------------------------------------------------------


# Install pipx using system's python3. (which we NEVER change, see previous point)
# We do not use 'apt-get install -y pipx' because that installs an old version of pipx which we cannot upgrade.
# We install pipx using pip to make sure we got latest version of pipx.
# To install pipx we temporary install pip to use it to install pipx and then remove it again.
# We do not want to keep pip installed, because it can break system packages dependent on the system python and its modules. 
RUN sudo apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y  \
        python3-pip \
    && pip install pipx \
    && apt-get purge -y python3-pip \
    && rm -rf /var/lib/apt/lists/*    


#-----------------------------------------------------------------------------------------------------------------------------
#  Install pythonX.Y for development
#-----------------------------------------------------------------------------------------------------------------------------

ENV PYTHONVERSION="3.8"


# Install pythonX.Y for development
# - pythonX.Y-full : full installation of pythonX.Y
# - pythonX.Y-dev : python c-headers to compile c-extensions
# - pythonX.Y does not have pip installed because we should not modify the distribution directly,
#   instead it comes with the venv module already installed,
#   which we can use in projects as:
#     $ pythonX.Y -mvenv .venv
#     $ source .venv/bin/activate
#     $ pip install ...        -> install in local virtual environment in project
RUN add-apt-repository ppa:deadsnakes/ppa \
    && sudo apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y  \
        python${PYTHONVERSION}-full \
        python${PYTHONVERSION}-dev  \
    && rm -rf /var/lib/apt/lists/* 

# NOTE: if we really need pip for directly changing the distribution, we can install it as follows:    
#    && python -m ensurepip --upgrade \
#    && python -m pip  install --upgrade pip 

# installs pythonX.Y at: 
#   /usr/lib/pythonX.Y
#   /usr/share/doc/pythonX.Y
#   /usr/local/lib/pythonX.Y  dist-packages

# IMPORTANT do not change the default python version with the alternative tool on the linux system because 
#           it can break python scripts in system packages which use /usr/bin/python3 thinking it is the 
#           system's python with specific versions of modules/packages. A system package can break by a 
#           different version of a python package for which it is not tested.
#           However as end-user you can change your default python version locally by changing the PATH 
#           environment variable such that its path points to desired python version first!
#           This doesn't change the system's python version in /usr/bin/python3 !!

# 
#-----------------------------------------------------------------------------------------------------------------------------
# install gui program in /home/$SESUSER/bin : ev3dev2simulator
#-----------------------------------------------------------------------------------------------------------------------------

# install dependencies for ev3dev2simulator
# - build-essential: provides c-compiler ; eg. to build python c-extensions
# - libasound2-dev: development package for ALSA sound system linux; needed to compile simpleaudio package which builds on ALSA.
# - alsa-utils espeak libespeak1 : system libraries needed for the the python pyttsx3 speech library
RUN sudo apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y  \
        build-essential libasound2-dev \     
        alsa-utils espeak  libespeak1 \
    && rm -rf /var/lib/apt/lists/*    

# NOTES:    
# - espeak not required, but does not give conflict, and can be convenient on the commandline
# - for py3-tts we also need alsa-utils package which supplies the  aplay tool which is needed for pyttsx3  
#     sudo apt-get install alsa-utils
# - https://github.com/thevickypedia/py3-tts
#     says ffmpeg package is required
#
#     problem:
#       arises when installing ffmpeg
#       ev3dev2simulator crashes with strip version of opengl version
#       -> ffmpeg install some extra mesa drivers
#             mesa-va-drivers mesa-vdpau-drivers ocl-icd-libopencl1 va-driver-all vdpau-driver-all
#          if you remove these packages then problem goes away
#     however:
#       https://github.com/thevickypedia/py3-tts
#        ffmpeg only needed for saving audio to file
#
#     simple fix: 
#       do not install ffmpeg (not really required, at least not for ev3dev2simulator)
#
# - tests for pyttsx3 and simpleaudio: 
#      python3 -c 'import pyttsx3; engine = pyttsx3.init(); engine.say("I will speak this text"); engine.runAndWait();'
#      python3 -c 'import simpleaudio.functionchecks as fc;fc.LeftRightCheck.run();'

        
# install ev3dev2simulator with pipx in SESUSER homedir independent of system's python using python ${PYTHONVERSION}   
RUN su -c "pipx install --python python${PYTHONVERSION} ev3dev2simulator==2.0.10" $SESUSER
# note: ev3dev2simulator==2.0.6  broken on python3.8 -> pyglet library breaks on some version parsing ?? -> still seems same pyglet version -> maybe opengl on system changed???
# note: in startwm.sh we add for SESUSER the ~/.local/bin/ to PATH. This is where pipx installs the ev3dev2simulator.

# we made wrapper script around ev3dev2simulator so end user can easily change its configuration (options)
COPY resources/bin/ev3dev2sim /home/$SESUSER/bin/ev3dev2sim
# to automatically launch it make a softlink with name guiprogram to it (then code in startwm.sh launches it which runs as $SESUSER)
RUN ln -r -s  /home/$SESUSER/bin/ev3dev2sim /home/$SESUSER/bin/guiprogram
RUN ln -r -s  /workspace/ /home/$SESUSER/workspace
# if you also install relaunch then the gui program will be automatically relaunched on exit (by startwm.sh)
COPY resources/bin/relaunch-gui-program  /home/$SESUSER/bin/relaunch-gui-program


#-----------------------------------------------------------------------------------------------------------------------------
# fix owner permissions for $SESUSER, because everything was copied into /home/$SESUSER as root user
#-----------------------------------------------------------------------------------------------------------------------------


RUN chmod a+x /home/$SESUSER/bin/*
RUN chown -R $SESUSER:$SESUSER /home/$SESUSER/bin


#-----------------------------------------------------------------------------------------------------------------------------
# launch xrdp server to which RDP clients can connect on port 3389 
#-----------------------------------------------------------------------------------------------------------------------------

EXPOSE 3389/tcp
#ENTRYPOINT ["/usr/bin/entrypoint"]
ENTRYPOINT ["/etc/xrdp/entrypoint.sh"]
# note: we put all start scrips in one location at /etc/xrdp/



