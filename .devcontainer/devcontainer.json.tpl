{
  "name": "${CONFIG_CONTAINER}",
  "runArgs": ["--name", "${CONFIG_CONTAINER}", "--hostname", "${CONFIG_CONTAINER}"],
  // image to load; build by Dockerfile first using the build options below
  "image": "${CONFIG_IMAGE}",
  //"initializeCommand": "docker build -f .devcontainer/Dockerfile  -t ${CONFIG_CONTAINER} .",
  // next is needed otherwise entrypoint in docker will be overridden; 
  // for ev3dev2simulator we need xrdp server running at entrypoint 
  "overrideCommand": false, 
  
  // do not stop container when closing vs code
  // default: to stop container
  "shutdownAction": "none", 
  
  "build": {
    "dockerfile": "./Dockerfile",
    //    "args": {
    //      "unused": "42"
    //    },
    //"options": [ "--tag=${CONFIG_IMAGE}" ] ->  will add extra tag next to vscodes one set by 'image' above
  },
  "remoteUser": "${CONFIG_USER}",
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached", 
  "workspaceFolder": "/workspace",

  // https://containers.dev/implementors/json_reference/#publishing-vs-forwarding-ports
  // https://code.visualstudio.com/docs/devcontainers/containers#_forwarding-or-publishing-a-port
  //  Docker has the concept of “publishing” ports when the container is created. 
  //  Published ports behave very much like ports you make available to your local network. 
  //  If your application only accepts calls from localhost, it will reject connections from
  //  published ports just as your local machine would for network calls.
  //  Forwarded ports, on the other hand, actually look like localhost to the application.
  //    'AppPort'      : does publishing by docker
  //    'forwardPorts' : does forwarding by vscode
  // Use 'forwardPorts' to make a list of ports inside the container available locally:
  //      Vscode implements 'forwardPorts' by forwarding a port from the container to the host on localhost only.
  //      The 'forwardPorts' is implemented by vscode itself, and not by docker,
  //      causing forwarded ports not to be listed or not bound in Docker Destop. 
  //      The "not bound" is shown when in the Dockerfile contains a line "EXPOSE myport", which only
  //      communicates that port myport provides a service of interest which you might publish/forward
  //      when using the container.
  // Using 'AppPort' or -p port on docker run command to publish the ports with docker. (so now docker is aware) 
  //      By default the port in the container is published from the host to the entire world, 
  //      and you have to specify explicitly -p 127.0.0.1:port to open it only to localhost on the host.    
  //      https://docs.docker.com/network/#published-ports
  //       Use the --publish or -p flag to make a port available to services outside of Docker. 
  //       This creates a firewall rule in the host, mapping a container port to a port on the Docker host to the outside world.
  //       IMPORTANT: if a service in a container only listens to socket on localhost, then
  //                  all network traffic to a container port never reaches the service            
  //                  To use AppPort the service need to listen on all interfaces (0.0.0.0).   
  //                  In that case use forwardPorts. But I prefer using fixing
  //                  the service to listen to all interfaces so that we can
  //                  also start the container with only docker and not needing vscode.
  "appPort": [${CONFIG_HOSTPORT_RDP}, ${CONFIG_HOSTPORT_EV3DEV2}, ${CONFIG_HOSTPORT_BLUETOOTH}],
  //"forwardPorts": [6840], -> we forward external port to internal port with socat so that we can launch container also without vscode
  // Configure tool-specific properties.
  "customizations": {
    // Configure properties specific to VS Code.
    // note: ms-python.python installs dependencies "ms-python.debugpy" and "ms-python.vscode-pylance"	
    "vscode": {
      "settings": {},
      "extensions": [
        "streetsidesoftware.code-spell-checker",
              "ms-python.python" 
      ]
    }
  }
  // Use 'postCreateCommand' to run commands after the container is created.
 // "postCreateCommand": "pip3 install -r requirements.txt"
  //"postCreateCommand": "id > /tmp/id.txt"
 // "postCreateCommand": "id > /workspace/id.txt"

 
}
