#This script will create a user, a primary group, and a supplementary group with one argument passed into the command line.
#Alex Sketers 3/1/22

#!/bin/bash
 
while getopts "adhu:g:G:p:" arg; do
    case $arg in
        u)
            USER_NAME=${OPTARG}
            ;;
        g)
            GROUP_NAME=${OPTARG}
            ;;
        G)
            SUPPLEMENTAL_GROUPS=${OPTARG}
            ;;
        a)
            ADD_USER_FLAG="1"
            ;;
        d)
            DELETE_USER_FLAG="1"
            ;;
        p)
            PASSWORD=${OPTARG}
            ;;
        h)
            usage
    esac
done
 
#functions area
function usage {
    echo "ADD USER: practice-script.sh -a -u USER_NAME -g GROUP_NAME -p PASSWORD [OPTIONAL: -G SUPPLEMENTAL_GROUPS]"
    echo
    echo "if using supplemental groups: provide a comma separated list"
    echo "example: testgroup,testgroup2"
    echo
    echo "OR"
    echo "DELETE USER: practice-script.sh -d -u USER_NAME"
}
 
function create_user {
    # user, primary group, password
    adduser $1 -m -g $2 -p $3
}
 
function create_user_with_multiple_groups {
    # user, primary group, supplemental groups, password
    adduser $1 -m -g $2 -G $3 -p $4
}
 
function create_group {
    groupadd $1
}
 
function create_supplemental_groups {
    for i in $(echo $1 | sed 's/,/ /g'); do
        groupadd $i
    done
}
 
function user_delete {
    sudo userdel -r $1
}
 
function group_delete {
    sudo groupdel $1
}
 
function count_number_of_users {
    getent group $1 | awk 'BEGIN { FS = ":" }; { print $4 }' | sed 's/,/ /g' | wc -w
}
 
function list_groups_for_user {
    id -Gn $1
}
 
#main code starts
if [ -z "$USER_NAME" ]; then
    echo "no username provided"
    usage
    exit
fi
 
if [ -z "$GROUP_NAME" ] && [ "$ADD_USER_FLAG" == "1" ]; then
    echo "no group name provided"
    usage
    exit
fi
 
if [ -z "$PASSWORD" ] && [ "$ADD_USER_FLAG" == "1" ]; then
    echo "no password provided when adding user"
    usage
    exit
fi
 
if [ "$ADD_USER_FLAG" == "1" ]; then
    if [ -z "$SUPPLEMENTAL_GROUPS" ]; then
        create_group $GROUP_NAME
        create_user $USER_NAME $GROUP_NAME $PASSWORD
        echo "done creating user $USER_NAME in group $GROUP_NAME"
    else
        create_group $GROUP_NAME
        create_supplemental_groups $SUPPLEMENTAL_GROUPS
        create_user_with_multiple_groups $USER_NAME $GROUP_NAME $SUPPLEMENTAL_GROUPS $PASSWORD
        echo "done creating user: $USER_NAME in primary group: $GROUP_NAME with supplemental groups: $SUPPLEMENTAL_GROUPS"
    fi
fi
 
if [ "$DELETE_USER_FLAG" == "1" ]; then
    echo "done deleting user: $USER_NAME"
 
    group_list=$(list_groups_for_user $USER_NAME)
    echo "group_list: $group_list"
 
    for i in $group_list; do
        counter=$(count_number_of_users $i)
        if [ $counter -le 1 ]; then
            echo "deleting group $i"
            group_delete $i
            echo "done deleting group $i"
        fi
    done
 
    echo "deleting user: $USER_NAME"
    user_delete $USER_NAME
    echo "done deleting user: $USER_NAME"
fi



