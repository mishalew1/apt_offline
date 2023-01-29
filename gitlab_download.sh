#!/bin/bash

DIR=/tmp/gitlab_pkgs
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
		echo -e "[$counter/$total] $pkg"
    	apt-get download $pkg
		((counter++))
	done

}


create_pkg_index(){
	pkg_index=Packages.gz
	dpkg-scanpackages . | gzip -c > $pkg_index
}


tarball_all_pkgs(){
	basename=${DIR##*/}
	tarball=${basename}.tar.gz
	cd ..
	tar -czvf $tarball $basename
}


verify_things(){
	echo -e "\n${DIR} size: "
	du -sh $DIR
	echo -e "\n$tarball size: "
	du -sh $tarball
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
    create_pkg_index
    tarball_all_pkgs
    verify_things
}
main
