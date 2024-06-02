#!/usr/bin/env bash


# setup venv for python project if not yet setup in /workspace mount
# -----------------------------------------------------------------
if [[ -d /workspace/ ]]
then (
    cd  /workspace
    # if [[ ! -d /workspace/.venv ]]
    # then  (
    #     # create venv
    #     cd /workspace
    #     python3 -m venv .venv
    #     # activate venv to install requirements.txt
    #     source .venv/bin/activate
    #     #pip install pip-tools
    #     pip install -r requirements.txt
    # ) fi
    #pythonversion=$(python3 -c'import sys;print(sys.version_info.major,sys.version_info.minor,sep="");')
    pythonversion=3.10
    LOCKFILE="lockfile.python${PYTHONVERSION}-linux.txt"
    if [[ -e "$LOCKFILE" ]]
    then 
        source pyproject.bash reactivate -l "$LOCKFILE"
    else 
        source pyproject.bash setup -p ${PYTHONVERSION} -l "$LOCKFILE"
    fi
           
    # make bash logins by default start activated	
    echo 'source /workspace/.venv/bin/activate' >> ~/.bashrc
) fi

# open ev3dev2simulator port also to outside world
# -------------------------------------------------------------------------------------------------------------------

#  - socat: to open localhost only service inside container to outside world so that we publish it on 
#           the dockerhost  localhost:port. The port becomes then internal on dockerhost.
#           We are basicly forwarding an internal container port  to and internal port on the docker host.

# Problem:
#  the ev3dev2simulator only listens to localhost:6840  
#  but for docker publishing to work it must listen also on port 6840 listening on outside world.
# Fix:
#  Forward external port to service listening only on a internal port (port on localhost) 
#
#  Only then we can publish that port to the the dockerhost on localhost:port, making it an internal port on docker host. 
#  With this socat and docker publishing combor,  we are basicly forwarding an internal container port  
#  to and internal port on the docker host.
#
# Forward external port to service listening only on a internal port with socat:
IPADDR=$(hostname -I)
socat tcp-l:6840,fork,reuseaddr,bind=$IPADDR tcp:127.0.0.1:6840	 &
