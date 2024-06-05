#!/usr/bin/env bash


# activate  ~/pyproject/src mount in bashrc only if mounted 
# ---------------------------------------------------------


# make bash logins by default start activated
echo 'source ~/pyproject/.venv/bin/activate' >> ~/.bashrc
echo 'cd ~/pyproject/src/' >> ~/.bashrc

# copy user's configured launch.json to projects .vscode/ config folder
if [[ ! -r  ~/pyproject/src/.vscode/launch.json ]]
then
    mkdir -p ~/pyproject/src/.vscode
    cp ~/.config/Code/User/launch.json ~/pyproject/src/.vscode/
fi

# if [[ -d ~/pyproject/src/ ]]
# then (
#     # make bash logins by default start activated
#     echo 'source ~/pyproject/.venv/bin/activate' >> ~/.bashrc
#     echo 'cd ~/pyproject/src/' >> ~/.bashrc
# ) fi

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
socat tcp-l:6841,fork,reuseaddr,bind=$IPADDR tcp:127.0.0.1:6841	 &
