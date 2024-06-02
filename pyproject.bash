#IMPORTANT: this file must be read by current bash using 'source' command, otherwise the current shell cannot be activated!

#-----------------------------------------------------------------------------
#             initialize 
#-----------------------------------------------------------------------------

# default lockfile
LOCKFILE="lockfile.txt"
# default python version  is python3; normalize default python3 version on this system to format "major.minor" 
DEFAULT_PYTHONVERSION=$("python3" -c 'import sys; print(sys.version_info[0],sys.version_info[1],sep=".")' 2>/dev/null ) || { echo "ERROR: python3 is not installed" && return; }
  
#define usage message
read -r -d '' USAGE << EOF
NAME
       source pyproject.bash - Setup the exact same Python development project anywhere.

USAGE  
       source pyproject.bash setup [-l LOCKFILE] [-p PYTHONVERSION] [-f] [-v]
       source pyproject.bash reactivate [-l LOCKFILE] [-v]
       source pyproject.bash help|info|activate|build|clean
   
DESCRIPTION   
    Effortless and quickly setup the exact same Python development project anywhere.

    A wrapper script around Python's venv and pip-tools to EASE Python project maintenance.
    Using a development's lockfile, stored in your repository, it automates setting up the
    Python virtual environment with the same python version and EXACT same dependencies at any
    location you want. 
 
    How do you use it? Easy, first setup your project with the 'setup' command. The 'setup'
    command determines the required dependencies from the config files, and then locks
    these dependencies in a lockfile, so we can easily recreate the same developer
    environment. Then at another location 'git clone' the project, and execute the
    'reactivate' command. The 'reactive' command then uses the info in the lockfile to
    reactive the project exactly the same! Using the 'info' command we can always
    easily view the current project status. With the 'build' command we can build
    a redistributable package(wheel). And if you only want to open the project
    in a new bash shell you can just use the 'activate' command to just activate its
    sandboxed environment in the new shell.

    A more extensive tutorial is at https://github.com/harcokuppens/pyproject.bash .


COMMANDS

 setup 
    Setup project from config files pyproject.toml and context.txt(optional).

    Creates a lockfile from these config files (using pip-compile), then reactivates
    the project (see next command). 

    The setup command locks the dependencies of the project to fixed versions in the
    lockfile. This lockfile allows us to reactivate the project with the exact same
    dependencies on other development locations. The lockfile is by default
    lockfile.txt but can be changed with the -l option. This make multiple lockfiles
    for different platforms possible. If the lockfile already exists, then your are
    first asked permission to overwrite it. With the option '-f' you can force
    overwrite. With the '-v' option the pip-tools give more verbose output.

    The default python version used is python3, which on this system is python${DEFAULT_PYTHONVERSION}.
    Most systems have python3 set to a reasonable version, and is therefore a
    reasonable default choice. However if your project requires a specific python
    version, you can require this version with the -p option. If you want to use the
    same python version as in an already existing lockfile, you can use the 'info'
    command to find out which python version that lockfile uses. The 'info' command
    also lists all available python versions on the system.

    The pyproject.toml is the new standard config file to configure your python project.
    The context.txt config file is to configure your context projects dependencies
    during development. (see explanation below).

    The context.txt and the generated lockfile are only used during development.
               
  reactivate 
    Reactivates an already setup project with an existing lockfile.
    
    Creates (if not yet exists) venv with python version in lockfile, activates venv,
    and syncs venv to lockfile (using pip-sync). Syncing venv means packages listed
    in the lockfile are installed, and packages installed not listed in the lockfile
    are uninstalled. The lockfile is by default '$LOCKFILE' but a different lockfile
    can be specified with the -l option. With the '-v' option the pip-tools give more 
    verbose output.
                           
  activate 
    Activates project in a (new) bash shell (requires venv up to date)
    
    Only activates venv in current bash shell; convenient for opening the project
    in a new bash shell. 

  build
    Build distributable package(wheel) of project in dist/ folder.  
            
  clean
    Cleanup project virtual environment.

    Deactivates project and removes .venv, but keeps the lockfile(s). Using the
    lockfile the project can be reactivated.
            
  info 
    Show project status.

    Lists details of current venv, lockfiles and python versions.               

  help 
    Displays this documentation.



PRACTICAL USAGE

    Normally a project gets 'setup' once, after which you store the lockfile in your project
    repository. Then on each new checkout of the project you only need to 'reactivate' it
    with the stored lockfile to get the exact same development setup.

    You only need to run 'setup' again when
      - you changed the project dependencies in pyproject.toml/context.txt or 
      - you changed platform: on run 'setup' if some python packages differ in dependencies
        for the change in platform. You should then keep a specific lockfile per platform.
        You can do this by using the '-l LOCKFILE' option to specify a platform specific
        lockfile. For example for macos arm64 we could use 'lockfile.macos-arm64.txt'.
      - When you change the python version of your project. Package versions can depend on
        python version. First run 'source project.bash clean' to remove the old '.venv'
        folder. Then run the 'setup' command with the new python version in the the '-p
        PYTHONVERSION' option.
 
    Because the '.venv' folder can be recreated it should not be include in your repository.
    You can even 'clean' the project from its '.venv' folder to reduce storage space for the
    project, and recreate it using the 'reactivate' command when you want to develop in the
    project again.

  
    
CONTEXT PROJECTS
    
    Your project may have some related projects on which your project depends, or your
    project is a dependency off. We call them 'context' projects, because these are in the
    context of your project. Often during development when making changes to your project
    you may need related changes in the context projects. Using editable installs python
    allows us to also install these context projects editable in your project. Because the
    editable installs are only needed during development we do not want to configure them
    in the pyproject.toml config. The latter file is used for building a production ready
    release package with 'python -m build'. Therefore we use a separate configfile
    'context.txt' in which we configure the editable installs purely used for development.

    The convention is to git clone a context project X into the context/X/ subdir of
    your project, and the add a line '-e context/X' to the context.txt config file.
    Also the main project is added with a line '-e .' to the context.txt config file.
    Editable install of the main project is required if your project uses the
    src-layout, because otherwise python files are in the src/ subdirectory won't be
    made available on the PYTHONPATH automatically. The editable install of your main
    project solves that!

    After git cloning the main project, then git cloning of the context projects into the
    context folder must be done manually or by a custom script.  
    Then the wrapper script can do all dependencies installs, including the editable
    installs automatically for you. The editable installs are also added to the
    project's lockfile, so if we later need to reactivate the project the editable installs
    are also done again.
 
    An example project using context projects:
    
        https://github.com/ev3dev-python-tools/thonny-ev3dev
 
    The context.txt and the lockfile are only used during development. 
    For production we only need pyproject.toml.
    

ABOUT WRAPPER SCRIPT

    Why not use venv and pip-tools directly? The wrapper script saves you from many manual
    steps using these tools, where often you have to lookup in the documentation how you
    install and use these tools. The wrapper script automates these steps, and can directly
    placed in your repository for direct usage. And if you forgot something, you just run the
    script to lookup its internal documentation. Easy as that!

    This wrapper script is used only during development. In production we are more liberal in
    requiring which versions of a dependency we allow, otherwise we would get unresolvable
    conflicts with other packages requiring the same dependency. But in production we setup an
    virtual environment only containing the package you are developing. During development we
    want every dependency locked to a specific version. We first want to develop in that
    strict environment, and not be distracted by bugs caused by a different version of a
    dependency. In a later phase, when the software is more stable, we can test
    with a more liberal version dependency.

    The wrapper script requires a modern 'pyproject.toml' project configuration setup, 
    from which it can reads the projects dependencies. It also requires bash installed.
    On Windows machines you can install the required bash with 'Git for Windows' or 'WSL2'.
    
    For more details about the wrapped tools see:

      * https://docs.python.org/3/library/venv.html
      * https://pip-tools.readthedocs.io
  
EOF


    read -r -d '' SHORTUSAGE << EOF
USAGE  
       source pyproject.bash setup [-l LOCKFILE] [-p PYTHONVERSION] [-f] [-v]
       source pyproject.bash reactivate [-l LOCKFILE] [-v]
       source pyproject.bash help|info|activate|build|clean
       
Try 'source pyproject.bash help' for more information.
EOF


#-----------------------------------------------------------------------------
#             helper functions 
#-----------------------------------------------------------------------------

error() {
    printf "\nERROR: $*\n\n"
}
error_usage() {
    printf "\nERROR: $*\n\n$SHORTUSAGE\n\n"
}

info() {
    echo "INFO: $*"
}

info_cmd() {
    echo "CMD: $*"
}

have_python_cmd() {
    python_cmd="$1"
    $python_cmd --version 1>/dev/null  2>/dev/null
}

cleanup_env() {
    CLEANUPDIR="/tmp/venv_pid$$_date$(date '+%Y%m%d_time%H%M')"
    info "cleanup .venv by moving it to $CLEANUPDIR; moving allows restoring by moving back"
    info_cmd "mv .venv '$CLEANUPDIR'"
    if mv .venv "$CLEANUPDIR"
    then 
        info "cleanup succeeded"
    else 
        error "cleanup failed"
        return 1
    fi  
}

setup_env() {
    info "activate venv with latest pip and pip-tools" 
    info_cmd "source .venv/bin/activate"                         
    source .venv/bin/activate   
    info_cmd "pip install $PIPTOOLS_VERBOSE --upgrade pip"
    pip install $PIPTOOLS_VERBOSE --upgrade pip                
    info_cmd "pip install $PIPTOOLS_VERBOSE pip-tools build"
    pip install $PIPTOOLS_VERBOSE pip-tools build
}

sync_env() {
    info "synchronize venv with lockfile"
    # pip-sync uses the $LOCKFILE stored in the git repo. 
    info_cmd "pip-sync $PIPTOOLS_VERBOSE '$LOCKFILE'" 
    pip-sync $PIPTOOLS_VERBOSE "$LOCKFILE"    
    info_cmd "ln -s -r '$LOCKFILE' .venv/piptools-lockfile"  
    ln -s -f -r "$LOCKFILE" .venv/piptools-lockfile
}


#-----------------------------------------------------------------------------
#             parse command and options 
#-----------------------------------------------------------------------------

FORCE="false"
VERBOSE="false"
REQ_PYTHONVERSION=""

# first argument is always command 
# note if CMD not matched in script then at end of script the USAGE is printed.
CMD="$1"
shift

while [[ -n "$1"  ]] 
do
    arg="$1"
    case $arg in 
    	"-l" ) 
            if [[ "$CMD" != "setup" && "$CMD" != "reactivate" ]]
            then
                error_usage "option -l not allowed for command $CMD"
                return 1
            fi 
            if [[ -z "$2" ]]
            then 
                error_usage "missing value for option -l"
                return 1
            fi       
            LOCKFILE="$2"
            shift 2
    		;;          
    	"-p" ) 
            if [[ "$CMD" != "setup" ]]
            then
                error_usage "option -p not allowed for command $CMD"
                return 1
            fi 
            if [[ -z "$2" ]]
            then 
                error_usage "missing value for option -p"
                return 1
            fi 
            REQ_PYTHONVERSION="$2"
            shift 2 
            
            # make sure python version is installed
            have_python_cmd "python$REQ_PYTHONVERSION" ||  { 
              error "requested python version '$REQ_PYTHONVERSION' is not installed." 
              return 1
            }
            # normalize python version to major.minor format
            REQ_PYTHONVERSION=$("python$REQ_PYTHONVERSION" -c 'import sys; print(sys.version_info[0],sys.version_info[1],sep=".")') 
    
            info "REQUESTED PYTHONVERSION: $REQ_PYTHONVERSION"
    		;;    
    	"-f" ) 
            FORCE="true"
            info "FORCE: $FORCE"
            shift
            ;;
    	"-v" ) 
            VERBOSE="true"
            info "VERBOSE: $VERBOSE"
            shift
    		;;                      
    	"-"* ) error_usage "invalid option '$arg'"
            return 1
            ;;   
        * ) error_usage "invalid argument '$arg'"
            return 1
            ;;
    esac
done

if [[ "$VERBOSE" == "true" ]]
then
    PIPTOOLS_VERBOSE=""
else 
    PIPTOOLS_VERBOSE="-q"    
fi    


#-----------------------------------------------------------------------------
#             handle commands 
#-----------------------------------------------------------------------------

if [[ "$CMD" == "setup" ]]
then
    
    if [[ ! -e pyproject.toml ]]
    then 
        error "required pyproject.toml not found"
        return 1
    fi
    
    info "Creating LOCKFILE: $LOCKFILE"
    
    if [[ -e "$LOCKFILE" && "$FORCE" == "false" ]]
    then
        while true; do
            echo ""
            echo "Lockfile '$LOCKFILE' already exists."
            read -p "Do you want to overwrite? (y/n) " yn
            case $yn in 
            	[yY] ) echo ok, we will proceed;
            		break;;
            	[nN] ) echo exiting...;
            		return;;
            	* ) echo invalid response;;
            esac
        done
    fi        
    
    # verify existing venv is compatible, otherwise clean it up
    if [[ -d .venv ]]
    then
        # make sure python in venv is still installed on the system   
        if have_python_cmd ".venv/bin/python" 
        then
            VENV_PYTHONVERSION=$(.venv/bin/python -c 'import sys; print(sys.version_info[0],sys.version_info[1],sep=".")')
            if [[ -n "$REQ_PYTHONVERSION" ]]
            then
                # user requested version
                if [[ "$REQ_PYTHONVERSION" == "$VENV_PYTHONVERSION" ]]
                then  
                    info "reusing existing venv with python$VENV_PYTHONVERSION"        
                else
                    info "cleanup and renew venv, because python version used by venv($VENV_PYTHONVERSION) does not match python version required($REQ_PYTHONVERSION)."
                    cleanup_env   
                fi
            else 
                # use default version
                if [[ "$DEFAULT_PYTHONVERSION" == "$VENV_PYTHONVERSION" ]]
                then
                    info "reusing existing venv with python$VENV_PYTHONVERSION"                            
                else    
                   info "cleanup and renew venv, because python version used by venv($VENV_PYTHONVERSION) does not match default python version($DEFAULT_PYTHONVERSION)."                    
                   cleanup_env   
                fi                    
            fi             
        else 
          info "cleanup and renew venv, because python version used by venv is not installed anymore."
          cleanup_env
        fi
    fi

    # case we do not have a venv (anymore), create a new one 
    if [[ ! -d .venv ]]
    then          
        if [[ -n "$REQ_PYTHONVERSION" ]]
        then
            info "create new venv with the requested python version $REQ_PYTHONVERSION"
            info_cmd "python$REQ_PYTHONVERSION -m venv .venv"
            "python$REQ_PYTHONVERSION" -m venv .venv        
        else                  
            info "create new venv with default python version $DEFAULT_PYTHONVERSION"
            info_cmd "python$DEFAULT_PYTHONVERSION -m venv .venv"
            "python$DEFAULT_PYTHONVERSION" -m venv .venv
        fi 
    fi 

    setup_env
    
    if [[ -e "context.txt" ]]
    then
        info "create lockfile from dependencies in pyproject.toml and context.txt"
        info_cmd "pip-compile $PIPTOOLS_VERBOSE -o '$LOCKFILE' pyproject.toml context.txt"
        pip-compile $PIPTOOLS_VERBOSE -o "$LOCKFILE" pyproject.toml context.txt  || { error "reading dependencies from pyproject.py and context.txt" ; return 1; }
    else
        info "create lockfile from dependencies in pyproject.toml"
        info_cmd "pip-compile $PIPTOOLS_VERBOSE -o '$LOCKFILE' pyproject.toml"
        pip-compile $PIPTOOLS_VERBOSE -o "$LOCKFILE" pyproject.toml || { error "reading dependencies from pyproject.py" ; return 1; }
    fi      
    
    sync_env
    
    echo ""
    echo "initialised and activated project"
    return 
fi


if [[ "$CMD" == "reactivate" ]]  
then  
    
    if [[ ! -e pyproject.toml ]]
    then 
        error "required pyproject.toml not found"
        return 1
    fi
    
    info "Using LOCKFILE: $LOCKFILE"
    
    if [[ ! -e "$LOCKFILE"  ]]
    then 
        error "no lockfile '$LOCKFILE' found" 
        return 1
    fi   
       
    LOCK_PYTHONVERSION=$(grep autogenerated "$LOCKFILE" | sed 's/.*Python //')
    # make sure python in lockfile is installed on the system   
    info "Found python version $LOCK_PYTHONVERSION in lockfile '$LOCKFILE'"      
    have_python_cmd "python$LOCK_PYTHONVERSION" ||  { 
      error "python version $LOCK_PYTHONVERSION used in lockfile '$LOCKFILE' is not installed on this system." 
      return 1
    } 
    

    # verify existing venv is compatible, otherwise clean it up
    if [[ -d .venv ]]
    then
        # make sure python in venv is still installed on the system   
        if have_python_cmd ".venv/bin/python" 
        then
            VENV_PYTHONVERSION=$(.venv/bin/python -c 'import sys; print(sys.version_info[0],sys.version_info[1],sep=".")')
            if [[ "$LOCK_PYTHONVERSION" == "$VENV_PYTHONVERSION" ]]
            then  
                info "Compatible venv for python$LOCK_PYTHONVERSION found: reused in reactivate."        
            else
                info "cleanup and renew venv, because python version used by venv($VENV_PYTHONVERSION) does not match python version in lockfile($LOCK_PYTHONVERSION)."
                cleanup_env           
            fi             
        else 
          info "cleanup and renew venv, because python version used by venv is not installed anymore."
          cleanup_env
        fi
    fi

    # in case we do not have a venv (anymore), create a new one 
    if [[ ! -d .venv ]]
    then          
        info "create new venv with python version $LOCK_PYTHONVERSION found in lockfile '$LOCKFILE'"
        info_cmd "python$LOCK_PYTHONVERSION -m venv .venv"
        "python$LOCK_PYTHONVERSION" -m venv .venv 
    fi 

    setup_env
        
    sync_env
    
    echo ""
    echo "reactivated project"
    return
fi



if [[ "$CMD" == "info" ]]  
then      
    
    echo ""
    
    if [[ -d .venv ]]
    then
        # check directory in which python command resides is same .venv/bin in current directory
        if [[ "$(cd $(dirname $(which python)) && pwd -P)" == "$( pwd -P )/.venv/bin" ]]
        then
            echo "project venv: ACTIVE" 
        else 
            echo "project venv: INACTIVE"
        fi 
    else      
        echo "project venv: INACTIVE (missing .venv folder)"
    fi 
    configfiles=$(command ls -r pyproject.toml context.txt 2>/dev/null)
    configfiles=${configfiles:-MISSING}
    echo "project config: " $configfiles
    if [[ ! -e pyproject.toml ]]
    then 
        echo "WARNING: project is not configured"
        echo "         missing REQUIRED pyproject.toml"
    fi
    
    echo ""
    
    if [[ -d .venv ]]
    then 
        echo "venv folder: yes"
    
        VENV_LOCKFILE=$(ls -l .venv/piptools-lockfile 2>/dev/null | sed 's/^.* -> ..\///')
        echo "venv synced with LOCKFILE: " ${VENV_LOCKFILE:-UNKNOWN}
        
        if have_python_cmd ".venv/bin/python" 
        then
            VENV_PYTHONVERSION=$(.venv/bin/python -c 'import sys; print(sys.version_info[0],sys.version_info[1],sep=".")')
            echo "venv PYTHON VERSION:"  $VENV_PYTHONVERSION           
        else 
            echo "PROBLEM: python version used by venv is not installed anymore."
        fi      
         
        # check directory in which python command resides is same .venv/bin in current directory
        if [[ "$(cd $(dirname $(which python)) && pwd -P)" == "$( pwd -P )/.venv/bin" ]]
        then
            echo "venv: activated" 
        else 
            if [[ "$VIRTUAL_ENV" == "" ]]
            then 
               echo "venv: NOT activated"
            else 
               echo "venv: NOT activated for current project"
            fi 
        fi 
      
    else      
        echo "venv folder: no"
    fi    
    
    
    echo ""
    
    # https://www.baeldung.com/linux/compgen-command-usage
    python_versions=$(compgen -c python3 |grep '\.' |grep -v config |sed 's/python3.//' |sort -n |uniq |sed 's/^/python3./')
    printf "python versions available on this system:\n\n"
    echo "$python_versions" | sed 's/^/    /'
    
    echo ""
    
    printf "lockfiles with corresponding python versions:\n\n"
    printf "    %-60s%s\n" "LOCKFILE" "PYTHON VERSION"
    printf "    %-60s%s\n" "--------" "--------------"    
    for f in $(compgen -f lockfile)
    do 
       version=$(grep autogenerated "$f" | sed 's/.*Python //') 
       version=${version:-UNKNOWN}
       printf "    %-60s%s\n" "$f" "$version"
    done
    
    echo ""
    
    return
fi
    
if [[ "$CMD" == "activate" ]]  
then      
    if [[ ! -d .venv ]]
    then 
        error "no .venv folder found: first reactivate or setup project before you can activate"
        return 1
    fi

    info_cmd "source .venv/bin/activate"
    source .venv/bin/activate
    
    echo ""
    VENV_PYTHONVERSION=$(python -c 'import sys; print(sys.version_info[0],sys.version_info[1],sep=".")')
    echo "activated project with python$VENV_PYTHONVERSION; deactivate with the 'deactivate' command"
    return
fi


if [[ "$CMD" == "build" ]]  
then  
    
    if [[ ! -e pyproject.toml ]]
    then 
        error "required pyproject.toml not found"
        return 1
    fi
    
    if [[ ! -d .venv ]]
    then 
        error "no .venv folder found: first reactivate or setup project before you can build"
        return 1
    fi     
    
    # check directory in which python command resides is same .venv/bin in current directory
    if [[ "$(cd $(dirname $(which python)) && pwd -P)" == "$( pwd -P )/.venv/bin" ]]
    then
        info "build wheel"
        info_cmd "python -m build --wheel"
        python -m build --wheel
    else 
        if [[ "$VIRTUAL_ENV" == "" ]]
        then 
           error "venv NOT activated: first activate before you can build"
           return 1
        else 
           error "venv NOT activated for current project:  first activate current project before you can build"
           return 1
        fi 
    fi 
    return  
fi


if [[ "$CMD" == "clean" ]]  
then  
    if [[ ! -d .venv ]]
    then 
        info "no .venv folder found: nothing to clean"
        return 
    fi     
    
    # check directory in which python command resides is same .venv/bin in current directory
    if [[ "$(cd $(dirname $(which python)) && pwd -P)" == "$( pwd -P )/.venv/bin" ]]
    then
        info "deactivate venv"
        info_cmd "deactivate"
        deactivate 
    else 
        if [[ "$VIRTUAL_ENV" == "" ]]
        then 
           info "venv NOT activated"
        else 
           info "venv NOT activated for current project, so do not deactivate"
        fi 
    fi 
       
    info "keeping lockfile(s)" 
    cleanup_env
    return  
fi

if [[ "$CMD" == "help" ]]  
then
   echo "$USAGE" 
   return   
fi  

    
#-----------------------------------------------------------------------------
#             fallback if no command matches
#-----------------------------------------------------------------------------
    
# if no argument matched (note: $1 could already be set in shell)
printf "\nNAME\n       source pyproject.bash - Setup the exact same Python development project anywhere.\n"
printf "\n$SHORTUSAGE\n\n"


