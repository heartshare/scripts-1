#!/bin/bash

# This script is used to copy a database from a server to another.
# It has been created to simplify the migration process between two servers.

# This code is provided 'as-is'
# and released under the BSD 3-Clause License

SCRIPT_PATH=$(cd $(dirname $0); pwd)
ssh_url="user@plesk.domain.com"

DB_ADMIN_USER="admin"
DB_ADMIN_PASS="password"

read -p "DB User: " db_user
read -p "Old database name: "$db_user old_db_name
old_db_name=$db_user""$old_db_name
read -p "New database name: "$db_user"_" new_db_name
new_db_name=$db_user"_"$new_db_name
read -s -p "DB Pass: " db_pass
echo
read -p "Drop tables? (y/n): " do_drop_tables


drop_opt=""
if [ "$do_drop_tables" == "y" ]; then
	drop_opt="--add-drop-table"
fi


dump_file=$(date +%F-%H-%M)-$new_db_name
DUMP_CMD="mysqldump $drop_opt -u $DB_ADMIN_USER -p$DB_ADMIN_PASS $old_db_name > "$dump_file".sql"

ssh $ssh_url "$DUMP_CMD; tar -cjf "$dump_file".tar.bz2 "$dump_file".sql; rm "$dump_file".sql"
scp $ssh_url":~/"$dump_file".tar.bz2" $SCRIPT_PATH"/"
ssh $ssh_url "rm "$dump_file".tar.bz2"
ls