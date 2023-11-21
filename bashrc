echo "Welcome ${USER}" "Home Directory : $HOME"

# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

 #aliases
if [ -f ~/alias ]; then
	echo "Executing alias configuration"
	source  ~/alias
fi



#terminal 
#export PS1='\[\e[0;36m\]\T \[\e[0;34m\]\u@\H \[\e[1;37m\]\w\[\e[0;37m\] \$ '
#export PS1='\[\e[0;34m\]\u@\H \[\e[1;37m\]\w\[\e[0;37m\] \n $ '
#export PS1="\[\033[38;5;11m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]@\h:\[$(tput sgr0)\]\[\033[38;5;6m\][\w]:\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\] \$"


### Proxy Setting
export http_proxy=127.0.0.1:3128
export https_proxy=127.0.0.1:3128 
export HTTP_PROXY=127.0.0.1:3128
export HTTPS_PROXY=127.0.0.1:3128


source ~/.git-completion.bash

export TERM='xterm-256color'

function _exit()              # Function to run upon exit of shell.
{
    echo -e "${BRed}Hasta la vista, baby${NC}"
}
trap _exit EXIT


function extract()      # Handy Extract Program
{
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xvjf $1     ;;
            *.tar.gz)    tar xvzf $1     ;;
            *.bz2)       bunzip2 $1      ;;
            *.rar)       unrar x $1      ;;
            *.gz)        gunzip $1       ;;
            *.tar)       tar xvf $1      ;;
            *.tbz2)      tar xvjf $1     ;;
            *.tgz)       tar xvzf $1     ;;
            *.zip)       unzip $1        ;;
            *.Z)         uncompress $1   ;;
            *.7z)        7z x $1         ;;
            *)           echo "'$1' cannot be extracted via >extract<" ;;
        esac
    else
        echo "'$1' is not a valid file!"
    fi
}

# Interesting 
#grep --color -E 'pattern|$' file

function ff() { find . -type f \( -iname "$@"'*.xml' -o -iname "$@"'*.java' \) -ls ; }

function fg() { find . -type f \( -iname '*.xml' -o -iname '*.java' \)  -print0 | xargs -0 grep -iHn --color "$@" ;}

#-exec grep -il '*'"$@"'*' {} \; }

#function fe() { find . -type f -iname '*'"${1:-}"'*' -exec ${2:-file} {} \;  ; }

#find . -type f -print0|xargs -0 strings -a --print-file-name|grep -i -E ':.*your_keyword_here'|less -S

# Find a file with pattern $1 in name and Execute $2 on it:
function fe() { find . -type f -iname "*""${1+"$@"}""*" -exec grep --color ${1+"$@"} {} \;  ; }

# Creates an archive (*.tar.gz) from given directory.
function maketar() { tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }

# Create a ZIP archive of a file or folder.
function makezip() { zip -r "${1%%/}.zip" "$1" ; }

# Make your directories and files access rights sane.
function sanitize() { chmod -R u=rwX,g=rX,o= "$@" ;}


function my_ps() { ps $@ -u $USER -o pid,%cpu,%mem,bsdtime,command ; }

function pp() { my_ps f | awk '!/awk/ && $0~var' var=${1:-".*"} ; }


function killps()   # kill by process name
{
    local pid pname sig="-TERM"   # default signal
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        echo "Usage: killps [-SIGNAL] pattern"
        return;
    fi
    if [ $# = 2 ]; then sig=$1 ; fi
    for pid in $(my_ps| awk '!/awk/ && $0~pat { print $1 }' pat=${!#} )
    do
        pname=$(my_ps | awk '$1~var { print $5 }' var=$pid )
        if ask "Kill process $pid <$pname> with signal $sig?"
            then kill $sig $pid
        fi
    done
}

function mydf()         # Pretty-print of 'df' output.
{                       # Inspired by 'dfc' utility.
    for fs ; do

        if [ ! -d $fs ]
        then
          echo -e $fs" :No such file or directory" ; continue
        fi

        local info=( $(command df -P $fs | awk 'END{ print $2,$3,$5 }') )
        local free=( $(command df -Pkh $fs | awk 'END{ print $4 }') )
        local nbstars=$(( 20 * ${info[1]} / ${info[0]} ))
        local out="["
        for ((j=0;j<20;j++)); do
            if [ ${j} -lt ${nbstars} ]; then
               out=$out"*"
            else
               out=$out"-"
            fi
        done
        out=${info[2]}" "$out"] ("$free" free on "$fs")"
        echo -e $out
    done
}


function my_ip() # Get IP adress on ethernet.
{
    MY_IP=$(/sbin/ifconfig eth0 | awk '/inet/ { print $2 } ' |
      sed -e s/addr://)
    echo ${MY_IP:-"Not connected"}
}

function ii()   # Get current host related info.
{
    echo -e "\nYou are logged on ${BRed}$HOST"
    echo -e "\n${BRed}Additionnal information:$NC " ; uname -a
    echo -e "\n${BRed}Users logged on:$NC " ; w -hs |
             cut -d " " -f1 | sort | uniq
    echo -e "\n${BRed}Current date :$NC " ; date
    echo -e "\n${BRed}Machine stats :$NC " ; uptime
    echo -e "\n${BRed}Memory stats :$NC " ; free
    echo -e "\n${BRed}Diskspace :$NC " ; mydf / $HOME
    echo -e "\n${BRed}Local IP Address :$NC" ; my_ip
    echo -e "\n${BRed}Open connections :$NC "; netstat -pan --inet;
    echo
}



function createrelease()
{

while getopts "C:M" arg; do
  case $arg in
    C) updatebranch=$current_branch;;
    M) updatebranch=$masterBranch;;
    \?) echo "Invalid Option : -$OPTARG" >&2 ; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument " ;exit 1 ;;
  esac
done


current_branch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')

echo "Current Brach name ; $current_branch "

# v1.0.0, v1.5.2, etc.
versionLabel=$(date '+%Y-%m-%d')

# establish branch and tag name variables
masterBranch=master
releaseBranch=release-$versionLabel
publishBranch=publish_$releaseBranch

# create the release branch from the -develop branch

echo "Creating release Branch $releaseBranch from $masterBranch "
git checkout -b $releaseBranch $masterBranch

echo "Creating Publish Branch $publishBranch from $masterBranch "
git checkout -b $publishBranch $masterBranch

}

function updatefrom()
{
if [ -f ~/localupdate.sh ]; then
	echo -e "Updating Local branch "
	source  ~/localupdate.sh
fi
}


#  Find a pattern in a set of files and highlight them:
#+ (needs a recent version of egrep).
function fstr()
{
    OPTIND=1
    local mycase=""
    local usage="fstr: find string in files.
Usage: fstr [-i] \"pattern\" [\"filename pattern\"] "
    while getopts :it opt
    do
        case "$opt" in
           i) mycase="-i " ;;
           *) echo "$usage"; return ;;
        esac
    done
    shift $(( $OPTIND - 1 ))
    if [ "$#" -lt 1 ]; then
        echo "$usage"
        return;
    fi
    find . -type f -name "${2:-*}" -print0 | \
xargs -0 egrep --color=always -sn ${case} "$1" 2>&- | more

}
