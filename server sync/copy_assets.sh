#!/bin/bash

# This script is used to copy the content of a given list of folders
# from one server to another. The current configuration comes from a plesk
# based server (though the destination is not using plesk)

# This code is provided 'as-is'
# and released under the BSD 3-Clause License

SCRIPT_PATH=$(cd $(dirname $0); pwd)
ssh_url="user@plesk.domain.com"

echo -n "Project name: "
read project_name

remote_www_dir="/var/www/vhosts"
local_www_dir=$remote_www_dir
remote_base_dir=$remote_www_dir"/"$project_name"/httpdocs"
local_base_dir=$local_www_dir"/dev."$project_name"/httpdocs"

echo "Project directory: "$remote_base_dir
echo


new_dir=""
dir_list=""
i=0

echo "Add relative path to compress and copy (enter ; to end): "
while [ "$new_dir" != ";" ]; do
	read -p "> " new_dir


	full_new_dir=false;
	if [ -n "$new_dir" ]; then # only if input is not empty...
		full_new_dir=$remote_base_dir"/"$new_dir
	
		if ( $(ssh $ssh_url "test -d \"$full_new_dir\"") ); then # if the remote directory exists...
			dir_list[i]="$new_dir"
			i=$i+1
		elif [ "$new_dir" != ";" ]; then
			echo "!! Not found: "$full_new_dir
		fi
	fi
done

if [ -n "$dir_list" ]; then # if there is something to do...
	echo
	echo "Going to copy the following folders:"
	printf "%s\n" "${dir_list[@]}"
	echo
	echo -n "Confirm? (y/n) "
	read user_conf

	SSH_CMD=""
	if [ "$user_conf" == "y" ]; then
		echo "Working ..."

		tar_name="$(date +%F-%H-%M)-"$project_name".tar.bz2"
		SSH_CMD="cd $remote_base_dir/; sudo tar -cpjf "$tar_name

		for i in ${dir_list[@]}; do
			SSH_CMD=$SSH_CMD" "$i
		done

		# create the archive and copy it locally:
		ssh -t $ssh_url "$SSH_CMD"
		scp $ssh_url":"$remote_base_dir"/"$tar_name $SCRIPT_PATH"/"
		ssh -t $ssh_url "sudo rm "$remote_base_dir"/"$tar_name

		# uncompress the archive:
		if ( $(sudo test -d "$local_base_dir") ); then
			sudo tar -xkjf $tar_name -C $local_base_dir"/"
			sudo rm $tar_name

			# set owner and group to www-data:
			for i in ${dir_list[@]}; do
				sudo chown -R www-data: $local_base_dir"/"$i
			done			
		else
			echo "Local folder does not exists: "$local_base_dir
		fi
	fi
fi
