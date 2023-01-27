#!/bin/bash

DIR=/tmp/mydebs
PKG_URL=https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh


package_list=(gitlab-ce curl openssh-server ca-certificates tzdata perl)


isRoot() {
	if [ "$EUID" -ne 0 ]; then
		echo "Has to be run as root"
		exit 1
	fi
}


install_script_dependencies(){
	apt update 
	apt install -y curl dpkg-dev
}


install_gitlab_repo(){
	script_location=/tmp/deb_script.sh
	curl --output $script_location $PKG_URL
	ls -lh $script_location
	bash $script_location
}


find_dependencies(){
	dependency_list=($(
		apt-cache depends --recurse \
    	    --no-recommends --no-suggests \
         	--no-conflicts --no-breaks \
      	    --no-replaces --no-enhances "${package_list[@]}"  \
			|  grep "^\w"  |  sort -u ))
}


download_dependencies(){
	counter=1
	total="${#dependency_list[@]}"
	
	for pkg in "${dependency_list[@]}"; do
		echo -e "\n$pkg [$counter\\$total]"
    	#apt-get download $pkg
		((counter+1))
	done
}


main(){
    isRoot
    install_script_dependencies
    install_gitlab_repo
    find_dependencies
    [[ -d $DIR ]] || mkdir $DIR
	chown _apt $DIR
    cd $DIR
    download_dependencies
}
main
