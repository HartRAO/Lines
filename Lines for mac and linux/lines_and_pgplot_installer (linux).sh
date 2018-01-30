#!/bin/sh
clear

echo "Hello Jabulani!"

# currect Directory
CURRENT_DIR=$PWD

# installing pgplot

# make /usr/local/src directory
sudo mkdir /usr/local/src

#sudo make

#sudo make cpg

# untar pgplot
sudo tar zxvf pgplot5.2.tar.gz  /usr/local/src

# This will make a subdirectory called sys_macosx with three configuration files.
sudo tar xvf pgplot_macosx_conf.tar  /usr/local/src/pgplot

# create /usr/local/lib/pgplot
sudo mkdir /usr/local/lib/pgplot

# Choose device drivers and open them in drivers.list file then copy it to the /usr/local/lib/pgplot
sudo cp drivers.list /usr/local/lib/pgplot

#run the makemake configuration script using one of my new config files: choose one depending on whether you will compile other programs with g77 or gfortran and in 32 or 64 bit.
#Either 
#sudo /usr/local/src/pgplot/makemake /usr/local/src/pgplot macosx g77_gcc_32
#OR: 
sudo /usr/local/src/pgplot/makemake /usr/local/src/pgplot macosx gfortran_gcc_32
#OR:
#sudo /usr/local/src/pgplot/makemake /usr/local/src/pgplot macosx gfortran_gcc_64



# change working directory
cd /usr/local/lib/pgplot 
sudo /usr/local/src/pgplot/makemake /usr/local/src/pgplot macosx gfortran_gcc_64

# PGplot is installed 

cd $CURRENT_DIR

# check if ~/.bashrc file exist 

filename="~/.bashrc"
if [ -f "$filename" ]
then
	echo "$filename found."
        cat add_to_bashrc >> ~/.bashrc
        
else
	echo "$filename not found."
        cp .bashrc ~/
        
fi

# now install lines.
cd lines/src/
sudo make
sudo make install
# return to the installing directory.
cd ../../ 


