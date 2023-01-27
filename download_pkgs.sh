#!/bin/bash
: '
This script downloads all recursive packages to the specified directory
Then creates a package listing to be used by apt sources
Finaly compresses the entire directory into a pkg_index to be moved to anoher system
'

# Variables
DIR=/tmp/deb_pkgs

package_list=(vim curl htop git rsync terminator openssh-server openssh-client)


isRoot() {
	if [ "$EUID" -ne 0 ]; then
		echo "Must be run as root"
		exit 1
	fi
}


install_script_dependencies(){
	apt update 
	apt install -y curl dpkg-dev
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
	pkg_index=$DIR/Packages.gz
	dpkg-scanpackages $DIR  | gzip -c > $pkg_index
}


tarball_all_pkgs(){
	tarball=/tmp/mydebs.tar.gz
	tar -czvf $tarball $DIR
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
