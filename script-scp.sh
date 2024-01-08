export RSYNC_RSH='ssh -o StrictHostKeyChecking=no'
sshpass -p "$1"  rsync ".ssh/id_rsa.pub" "$2@$3:.ssh/authorized_keys"