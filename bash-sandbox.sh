#!/bin/bash

if [ $# -eq 0 ]; then 
    usage
fi


function usage(){
    echo "$0 -e <env var file> -f <script filename>"
    exit 1
}

while getopts "e:f:" opt ; do 
    case $opt in 
        e) 
            export env_source=$(realpath $OPTARG)
        ;;
        f)
            export script_filename=$(realpath $OPTARG)
        ;;
        \?)
            usage
        ;;
    esac
done
shift $((OPTIND - 1))

echo $env_source $script_filename
temp_file=$(mktemp)
cat <<EOF >> $temp_file
#!/bin/bash
tput setab 1
tput setaf 7
tput bold
while inotifywait -q -e modify,attrib ${script_filename} ${env_source} >/dev/null; do 
    clear
    tput setaf 3; date +%Y.%M.%d-%H:%m.%S; tput setaf 7; echo
    for var in \$(set | egrep -o -i '^.*\(\)' | grep -v 'BASH_' | sed -e 's/.()//g' -e 's/^.*function\ //g'); do 
        unset -f \$var; 
        unset -v \$var;  
    done
    source ${env_source}
    ${script_filename}
done
tput sgr0
EOF
chmod +x $temp_file
$temp_file
rm $temp_file
