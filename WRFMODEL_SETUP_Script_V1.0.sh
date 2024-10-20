#####################################################################################
#!/bin/bash
#####################################################################################
#####################################################################################
#This is script will check basic pakage required to run WRF model
#It downloads and install libraries required to run WRF model
#Also, it  downloads and comiple WPS and WRF code
#In the last step, this scipt download some sample data to make test model run
#This scipt is tested for Ubuntu, centos and red-hat linux machine
#####################################################################################
#/////////////////////////////////////////////////////////////////////////////////
if [ -f $HOME/.profile ];then
        outenvfile=".profile"
fi

if [ -f $HOME/.bash_profile ];then
        outenvfile=".bash_profile"
fi
#///////////////////////////////////////////////////////////////////////////////////
#####################################################################################
SYSTEM_OS="$(grep -E '^(NAME)=' /etc/os-release)"
printf "\n $SYSTEM_OS"
printf "\n"
printf "\n"
source $HOME/$outenvfile
#======================================================================
pkglist=("gfortran" "gcc" "cpp" "ar" "head" "sed" "awk" "hostname" "sleep" "cat" "ln" "sort" "ls" "tar" "cp" "make" "touch" "cut" "mkdir" "tr" "expr" "mv" "uname" "file" "nm" "wc" "grep" "printf" "which" "gzip" "rm" "m4")

count=`echo ${#pkglist[@]}`

for i in $(seq $count); do
pkgname=${pkglist[i-1]}
pkg_status="$(which $pkgname 2> /dev/null)"
if [ -z "$pkg_status" ]
then 
      printf "|%-10s | %-30s | %-35s \n" "$pkgname" " = Not Found "
      read -p "Do want to install (y/n) = " pkgconfirm
      if [ $pkgconfirm == "y" ] || [ $pkgconfirm == "Y" ]
      then
       echo "Installing...Please provide super user password"
       sleep 2
       yumpkg="$(which yum 2> /dev/null)"
       if [ -z "$yumpkg" ];then    
       sudo yum install $pkgname
       fi
       
       aptpkg="$(which apt 2> /dev/null)"
       if [ -z $aptpkg ];then
       sudo apt install $pkgname
       fi
       newpkg_status="$(which $pkgname 2> /dev/null)"
      if [ -z "$pkg_status" ]
      then
       echo "$pkgname =  Not Found"
       echo "Please install $pkgname Manually to continue"
       exit
      fi
      fi 
else
      printf "|%-10s | %-30s | %-35s \n" "$pkgname" " = Found @ $(which $pkgname) "
fi
done
#=================================================================================
PATHWRF=$(pwd)
printf "\nThe WRF model code will install at default path : $PATHWRF\n"
printf "\n"
read -p "Do you want to choose the installtion path of WRF model (y/n) : " pathwrf
printf "\n"
if  [ $pathwrf == 'y' ] || [ $pathwrf == "Y" ];then
	read -p "Enter the path to install WRF code = " newpathwrf
	PATHWRF=$newpathwrf
fi
#===================================================================
prog_path=$(pwd)
mkdir $PATHWRF/Build_WRF 2> /dev/null
mkdir $PATHWRF/Build_WRF/LIBRARIES 2> /dev/null
path_WRFLIB=$PATHWRF/Build_WRF/LIBRARIES
pathWRF=$PATHWRF/Build_WRF
#/////////////////////////////////////////////////////////////////////////////////
#/////////////////////////////////////////////////////////////////////////////////

wrfpathstring="$(grep -c WRFLIBDIR $HOME/$outenvfile)"
if [ $wrfpathstring -eq 0 ];then
	echo "#//////////////PATH FOR WRF MODEL LIBRARAY/////////////" >>$HOME/$outenvfile
	echo " ">>$HOME/$outenvfile
	echo "export WRFLIBDIR=$path_WRFLIB" >>$HOME/$outenvfile
	echo " ">>$HOME/$outenvfile
fi
#=================================================================================
gccversionvalue=$(gcc --version | grep gcc | awk '{print $3}')
gccversion=$(gcc --version | awk '/gcc/ && ($3+0)<8.5{print "8.5.0"}')
if [ "$gccversion" == "8.5.0" ];then
	printf "\ngcc found with version $gccversionvalue"
	printf "\ngcc version must be 8.5.0 or later required to run WRF"
	printf "\nTo Instal gcc it might take longer time using this script"
	printf "\nIt is advisible to install gcc through repositories of precompiled packages"
	printf "\n"
	read -p "Do you want to continue to install gcc through this scipt (y/n) : " gccinstall
	if [ $gccinstall == "y" ] || [ $gccinstall == "Y" ];then
		printf "\n"
		outmsg="Installing gcc version : 8.5.0"
		printf "\n\t\t\t\t\t$outmsg"
		printf "\n"
		cd $path_WRFLIB
		wget --no-check-certificate https://gcc.gnu.org/pub/gcc/releases/gcc-8.5.0/gcc-8.5.0.tar.xz
		tar xvf gcc-8.5.0.tar.xz
		cd gcc-8.5.0
		./contrib/download_prerequisites
		./configure --prefix=$path_WRFLIB/gcc_8.5.0 --disable-multilib
		make && make install
		cd $path_WRFLIB
		rm -rf gcc-8.5*
		echo " "
		gccstring="$(grep -c gcc_8.5.0_Path $HOME/$outenvfile)"
		if [ $gccstring -eq 0 ];then
			echo " ">>$HOME/$outenvfile
			echo "############# gcc_8.5.0_Path Libraries ###########">>$HOME/$outenvfile
			echo export PATH="$"WRFLIBDIR/gcc_8.5.0/bin:"$"PATH>>$HOME/$outenvfile
			echo export LD_LIBRARY_PATH="$"WRFLIBDIR/gcc_8.5.0/lib64>>$HOME/$outenvfile
			source $HOME/$outenvfile
		fi
		gcc_version=$(gcc --version | grep gcc | awk '{print $3}')
		echo "gcc version = $gcc_version , installed @ $(which gcc)"
		echo ""
	else
		printf "\nPlease install gcc version 8.5 or later manually for WRF\n"
		exit
	fi
else
	source $HOME/$outenvfile
	printf "\ngcc found with version $gccversionvalue and compatible to run WRF model\n"
fi

compilerstring="$(grep -c Compiler_Path $HOME/$outenvfile)"
if [ $compilerstring -eq 0 ];then
	echo " ">>$HOME/$outenvfile
	echo "########### Compiler_Path for WRF Libraries#######">>$HOME/$outenvfile
	echo "export CC=gcc">>$HOME/$outenvfile
	echo "export CXX=g++">>$HOME/$outenvfile
	echo "export FC=gfortran">>$HOME/$outenvfile
	echo "export FCFLAGS=-m64">>$HOME/$outenvfile
	echo " ">>$HOME/$outenvfile
	source $HOME/$outenvfile
fi
#//////////////////////////////////////////////////////////////////////////////////
printf "\n\t\t\t\t======================================================================"
outmsg1="TEST for gcc and gfortran"
printf "\n\t\t\t\t\t\t$outmsg1"
printf "\n\t\t\t\t======================================================================\n"
printf "\nDownloading simple tests to verify the Fortran and C compiler\n"
printf "\n"
cd $pathWRF
mkdir TEST1 2> /dev/null
cd TEST1

wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_tests.tar

tar -xf Fortran_C_tests.tar

gfortran TEST_1_fortran_only_fixed.f
testmsg1=$(./a.out)
msgtest1=`echo $testmsg1|awk '{print match($0,"SUCCESS")}'`
if [ $msgtest1 -gt 0 ];then
	#printf "$testmsg1"
	printf "\n Test 1 = Passed for fortran only fixed format\n"
else
	printf "\n Test 1 = Failed for fortran only fixed format"
	printf "\n Check gcc and gfortran path and version is correct\n"
	exit
fi

gfortran TEST_2_fortran_only_free.f90
testmsg2=$(./a.out)
msgtest2=`echo $testmsg2|awk '{print match($0,"SUCCESS")}'`
if [ $msgtest2 -gt 0 ];then
	#printf "\n$testmsg2"
	printf "\n Test 2 = Passed for fortran only free format\n"
else
	printf "\n Test 2 = Failed for fortran only free format"
	printf "\n Check gcc and gfortran path and version is correct\n"
	exit
fi

gcc TEST_3_c_only.c
testmsg3=$(./a.out)
msgtest3=`echo $testmsg3|awk '{print match($0,"SUCCESS")}'`
if [ $msgtest3 -gt 0 ];then
	#printf "\n$testmsg3"
	printf "\n Test 3 = Passed for C only\n"
else
	printf "\n Test 3 = Failed for C only"
	printf "\n Check gcc and gfortran path and version is correct\n"
	exit
fi

gcc -c -m64 TEST_4_fortran+c_c.c
gfortran -c -m64 TEST_4_fortran+c_f.f90
gfortran -m64 TEST_4_fortran+c_f.o TEST_4_fortran+c_c.o
testmsg4=$(./a.out)
msgtest4=`echo $testmsg4|awk '{print match($0,"SUCCESS")}'`
if [ $msgtest4 -gt 0 ];then
	#printf "\n$testmsg4"
	printf "\n Test 4 = Passed for fortran calling c\n"
else
	printf "\n Test 4 = Failed for fortran calling c"
	printf "\n Check gcc and gfortran path and version is correct\n"
	printf "\n"
	exit
fi

cshtest=$(./TEST_csh.csh)
msgtest5=`echo $cshtest|awk '{print match($0,"SUCCESS")}'`
if [ $msgtest5 -gt 0 ];then
	#printf "\n$cshtest"
	printf "\n Test 5 = Passed for csh test\n"
else
	printf "\n Test 5 = Failed for csh test"
	printf "\n csh shell not found\n"
	printf "\n"
	exit
fi

perltest=$(./TEST_perl.pl)
msgtest6=`echo $perltest|awk '{print match($0,"SUCCESS")}'`
if [ $msgtest6 -gt 0 ];then
	#printf "\n$perltest"
	printf "\n Test 6 = Passed for perl test\n"
else
	printf "\n Test 6 = Failed for perl test"
	printf "\n perl not found\n"
	printf "\n"
	exit
fi

shtest=$(./TEST_sh.sh)
msgtest7=`echo $shtest|awk '{print match($0,"SUCCESS")}'`
if [ $msgtest7 -gt 0 ];then
	#printf "\n$shtest"
	printf "\n Test 7 = Passed for sh test\n "
	printf "\n"
else
	printf "\n Test 7 = Failed for sh test"
	printf "\n sh shell not found\n"
	printf "\n"
	exit
fi
cd $pathWRF
rm -rf TEST1

#///////////////////////////////////////////////////////////////////////////////////
printf "\n\t\t\t\t======================================================================"
outmsg2="Netcdf Installation"
printf "\n\t\t\t\t\t\t$outmsg2"
printf "\n\t\t\t\t======================================================================\n"
#==================================================================================
pathnetcdf1=$(which ncdump 2> /dev/null) 
if [ "$pathnetcdf1" != "$path_WRFLIB/netcdf/bin/ncdump" ];then
	printf "\n"
	printf "\n Downloading netcdf-c-4.7.2 .......\n"
	echo   " "
	cd $path_WRFLIB
	wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/netcdf-c-4.7.2.tar.gz
	tar xvf netcdf-c-4.7.2.tar.gz
	cd netcdf-c-4.7.2
	./configure --prefix=$path_WRFLIB/netcdf --disable-dap  --disable-netcdf-4 --disable-shared
	make && make install

	if [ ! -f "$path_WRFLIB/netcdf/bin/ncdump" ];then
		printf "\netcdf-c is not able to install. Please Install Manually\n"
		exit
	fi
	cd $path_WRFLIB
	rm -rf netcdf-c-4.7.2*
else
	source $HOME/$outenvfile
	printf "\nnetcdf-c already installed @ $path_WRFLIB/netcdf \n"
fi

netcdfstring="$(grep -c NETCDF_Path $HOME/$outenvfile)"
if [ $netcdfstring -eq 0 ];then
	echo " ">>$HOME/$outenvfile
	echo "############# NETCDF_Path Libraries ###########">>$HOME/$outenvfile
	echo export PATH="$"WRFLIBDIR/netcdf/bin:"$"PATH>>$HOME/$outenvfile
	echo export NETCDF="$"WRFLIBDIR/netcdf>>$HOME/$outenvfile
	source $HOME/$outenvfile
fi

pathnetcdf2=$(which nf-config 2> /dev/null)
if [ "$pathnetcdf2" != "$path_WRFLIB/netcdf/bin/nf-config" ];then
	echo   " "
	printf "\n Downloading netcdf-fortran-4.5.2 .......\n"
	echo   " "
	cd $path_WRFLIB
	wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/netcdf-fortran-4.5.2.tar.gz
	tar xvf netcdf-fortran-4.5.2.tar.gz
	cd netcdf-fortran-4.5.2
	CPPFLAGS=-I$path_WRFLIB/netcdf/include  LDFLAGS=-L$path_WRFLIB/netcdf/lib ./configure --prefix=$path_WRFLIB/netcdf --disable-dap  --disable-netcdf-4 --disable-shared
	make && make install
	if [ ! -f "$path_WRFLIB/netcdf/bin/nf-config" ];then
		printf "\nnetcdf-fortran is not able to install. Please Install Manually\n"
		exit
	fi
	cd $path_WRFLIB
	rm -rf netcdf-fortran*
else
	source $HOME/$outenvfile
	printf "\nnetcdf-fortran already installed @ $path_WRFLIB/netcdf \n"
fi
#///////////////////////////////////////////////////////////////////////////////////
printf "\n\t\t\t\t======================================================================"
outmsg3="MPICH Installation"
printf "\n\t\t\t\t\t\t$outmsg3"
printf "\n\t\t\t\t======================================================================\n"
#==================================================================================
pathmpich="$(which mpicc 2> /dev/null)"
if [ "$pathmpich" != "$path_WRFLIB/mpich/bin/mpicc" ];then
	printf "\n"
	printf "\n To Instal mpich it might take longer time.......\n"
	printf "\n Downloading mpich-3.0.4 .......\n"
	echo   " "
	cd $path_WRFLIB
	wget https://www.mpich.org/static/downloads/4.2.2/mpich-4.2.2.tar.gz
	tar xvf mpich-4.2.2.tar.gz
	cd mpich-4.2.2
	./configure --prefix=$path_WRFLIB/mpich
	make && make install
	if [ ! -f "$path_WRFLIB/mpich/bin/mpicc" ];then
		printf "\nMPICH is not able to install. Please Install Manually\n"
		exit
	fi
	cd $path_WRFLIB
	rm -rf mpich-3.0.4*
else
	source $HOME/$outenvfile
	printf "\nMPICH already installed @ $path_WRFLIB/mpich \n"
fi
mpichstring="$(grep -c MPICH_Path $HOME/$outenvfile)"
if [ $mpichstring -eq 0 ];then
	echo " ">>$HOME/$outenvfile
	echo "############# MPICH_Path Libraries ###########">>$HOME/$outenvfile
	echo export PATH="$"WRFLIBDIR/mpich/bin:"$"PATH>>$HOME/$outenvfile
	echo "export CXX=mpicxx">>$HOME/$outenvfile
	echo "export FC=mpif90">>$HOME/$outenvfile
	echo "export F77=mpif90">>$HOME/$outenvfile
	echo "export F90=mpif90">>$HOME/$outenvfile
	source $HOME/$outenvfile
fi
#====================================================
#///////////////////////////////////////////////////////////////////////////////////
printf "\n\t\t\t\t======================================================================"
outmsg4="Installation of Zlib, Libpng, Jasper  Libraries "
printf "\n\t\t\t\t$outmsg4"
printf "\n\t\t\t\t======================================================================"\n
#==================================================================================
pathgrib2="$(which jasper 2> /dev/null)"
if [ "$pathgrib2" != "$path_WRFLIB/grib2/bin/jasper" ];then
	printf "\n"
	printf "\n Downloading zlib-1.2.11 .......\n"
	echo   " "
	cd $path_WRFLIB
	wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/zlib-1.2.11.tar.gz
	tar xvf zlib-1.2.11.tar.gz
	cd zlib-1.2.11
	./configure --prefix=$path_WRFLIB/grib2
	make && make install
	cd $path_WRFLIB
	rm -rf zlib-1.2.11*
	printf "\n"
	printf "\n Downloading libpng-1.2.50 .......\n"
	echo   " "
	cd $path_WRFLIB
	wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/libpng-1.2.50.tar.gz
	tar xvf libpng-1.2.50.tar.gz
	cd libpng-1.2.50
	./configure --prefix=$path_WRFLIB/grib2
	make && make install
	cd $path_WRFLIB
	rm -rf libpng-1.2.50*
	printf "\n"
	printf "\n Downloading jasper-1.900.1 .......\n"
	echo   " "
	cd $path_WRFLIB
	wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz
	tar xvf jasper-1.900.1.tar.gz
	cd jasper-1.900.1
	./configure --prefix=$path_WRFLIB/grib2
	make && make install
	cd $path_WRFLIB
	rm -rf jasper-1.900.1*
else
	source $HOME/$outenvfile
	printf "\nZlib, Libpng, Jasper already installed @ $path_WRFLIB/grib2 \n"
fi
gribpathstring="$(grep -c GRIB2_Path $HOME/$outenvfile)"
if [ $gribpathstring -eq 0 ];then
	echo " ">>$HOME/$outenvfile
	echo "############# GRIB2_Path Libraries ###########">>$HOME/$outenvfile
	echo export PATH="$"WRFLIBDIR/grib2/bin:"$"PATH>>$HOME/$outenvfile
	echo export LD_LIBRARY_PATH="$"WRFLIBDIR/grib2/lib:"$"LD_LIBRARY_PATH>>$HOME/$outenvfile
	echo export JASPERLIB="$"WRFLIBDIR/grib2/lib>>$HOME/$outenvfile
	echo export JASPERINC="$"WRFLIBDIR/grib2/include>>$HOME/$outenvfile
	echo export LDFLAGS=-L"$"WRFLIBDIR/grib2/lib>>$HOME/$outenvfile
	echo export CPPFLAGS=-I"$"WRFLIBDIR/grib2/include>>$HOME/$outenvfile
	echo " ">>$HOME/$outenvfile
	echo "export WRFIO_NCD_LARGE_FILE_SUPPORT=1">>$HOME/$outenvfile
	source $HOME/$outenvfile
fi
#====================================================
#///////////////////////////////////////////////////////////////////////////////////
printf "\n\t\t\t\t======================================================================"
outmsg5="Installation of Ncl Ncarg 6.62 "
printf "\n\t\t\t\t$outmsg5"
printf "\n\t\t\t\t======================================================================\n"

ncl_status="$(which ncl 2> /dev/null)"
if [ -z "$ncl_status" ];then
	cd $path_WRFLIB
	mkdir ncl_6.6.2
	cd ncl_6.6.2
	wget --no-check-certificate https://www.earthsystemgrid.org/api/v1/dataset/ncl.662_2.nodap/file/ncl_ncarg-6.6.2-Debian7.11_64bit_nodap_gnu472.tar.gz
	tar -xvf ncl_ncarg-6.6.2-Debian7.11_64bit_nodap_gnu472.tar.gz
	cd $path_WRFLIB
	rm -rf ncl_ncarg-6.6.2-Debian7.11_64bit_nodap_gnu472.tar.gz
else
	source $HOME/$outenvfile
	printf "\n ncl already installed @ $ncl_status \n"
fi

nclpathstring="$(grep -c NCL_Path $HOME/$outenvfile)"
if [ $nclpathstring -eq 0 ] && [ -z "$ncl_status" ];then
	echo " ">>$HOME/$outenvfile
	echo "############# NCL_Path Libraries ###########">>$HOME/$outenvfile
	echo export NCARG_ROOT="$"WRFLIBDIR/ncl_6.6.2>>$HOME/$outenvfile
	echo export PATH="$"NCARG_ROOT/bin:"$"PATH>>$HOME/$outenvfile
	echo " ">>$HOME/$outenvfile
	source $HOME/$outenvfile
fi

#//////////////////////////////////////////////////////////////////////////////////
printf "\n\t\t\t\t======================================================================"
outmsg6="TEST for Netcdf and MPI compiler"
printf "\n\t\t\t\t$outmsg6"
printf "\n\t\t\t\t======================================================================\n"

printf "\nDownloading simple tests to verify the netcdf and MPI compiler\n"
printf "\n"
cd $pathWRF
mkdir TEST2 2> /dev/null
cd TEST2

wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_NETCDF_MPI_tests.tar
tar -xf Fortran_C_NETCDF_MPI_tests.tar

cp ${NETCDF}/include/netcdf.inc .
gfortran -c 01_fortran+c+netcdf_f.f
gcc -c 01_fortran+c+netcdf_c.c
gfortran 01_fortran+c+netcdf_f.o 01_fortran+c+netcdf_c.o -L${NETCDF}/lib -lnetcdff -lnetcdf
testmsg8=$(./a.out)
msgtest8=`echo $testmsg8|awk '{print match($0,"SUCCESS")}'`
if [ $msgtest8 -gt 0 ];then
	#printf "\n$testmsg8"
	printf "\n Test 1 = Passed for fortran + c + netcdf\n"
else
	printf "\n Test 1 = Failed"
	printf "\n Check gcc and gfortran path and version is correct\n"
	printf "\n"
	exit
fi


mpif90 -c 02_fortran+c+netcdf+mpi_f.f
mpicc -c 02_fortran+c+netcdf+mpi_c.c
mpif90 02_fortran+c+netcdf+mpi_f.o 02_fortran+c+netcdf+mpi_c.o -L${NETCDF}/lib -lnetcdff -lnetcdf
testmsg9=$(mpirun ./a.out)
msgtest9=`echo $testmsg9|awk '{print match($0,"SUCCESS")}'`
if [ $msgtest9 -gt 0 ];then
	#printf "\n$testmsg9"
	printf "\n Test 2 = Passed for fortran + c + netcdf + mpi\n"
else
	printf "\n Test 2 = Failed"
	printf "\n Check gcc and gfortran path and version is correct\n"
	printf "\n"
	exit
fi
cd $pathWRF
rm -rf TEST2
#//////////////////////////////////////////////////////////////////////////////////
printf "\n\t\t\t\t======================================================================"
outmsg7="Download and Compile WPS and WRF code"
printf "\n\t\t\t\t$outmsg7"
printf "\n\t\t\t\t======================================================================\n"
printf "\n"
#=================================================================================
source $HOME/$outenvfile
cd $pathWRF
modelpath=$(pwd)
if [ ! -f $modelpath/WRF/configure ];then
	wget --no-check-certificate https://github.com/wrf-model/WRF/releases/download/v4.6.0/v4.6.0.tar.gz
	tar xvf v4.6.0.tar.gz
	mv WRFV4.6.0 WRF
	rm -rf v4.6.0.tar.gz
fi

if [ ! -f $modelpath/WPS/configure ];then
	wget --no-check-certificate https://github.com/wrf-model/WPS/archive/refs/tags/v4.6.0.tar.gz
	tar xvf v4.6.0.tar.gz
	mv WPS-4.6.0 WPS
	rm -rf v4.6.0.tar.gz
fi

if [ ! -f $modelpath/WRF/main/wrf.exe ];then
	printf "\n\t\t......Configure and Compile the WRF code for real case.....\n"
	cd $modelpath/WRF
	#sed -i 's@"$NETCDF4_DEP_LIB"@"$NETCDF4_DEP_LIB"</dev/tty@g' configure
	sed -i 's\"$NETCDF4_DEP_LIB"\"$NETCDF4_DEP_LIB"</dev/tty\g' configure
	replaceline=$(grep -n ""$"response = <STDIN>" $modelpath/WRF/arch/Config.pl | head -n 1 | cut -d: -f1)
	sed -i ''$replaceline's\$response = <STDIN>\$response = 34\' $modelpath/WRF/arch/Config.pl
	replaceline=$(grep -n ""$"response = <STDIN>" $modelpath/WRF/arch/Config.pl | head -n 1 | cut -d: -f1)
	sed -i ''$replaceline's\$response = <STDIN>\$response = 1\' $modelpath/WRF/arch/Config.pl
	./configure
	./compile em_real
	printf "\n"
	printf "\n"
	printf "\n WRF Code configured for dmpar gcc and fortran architecture option no 34 with basin nesting option 1"
	printf "\n WRF Code compiled for real case (em_real)"
	printf "\n If you wish to configure and compile with other architecture please do manually once this finsihed"
	sleep 10
else 
	printf "\n WRF code compiled already\n"
fi

if [ ! -f $modelpath/WPS/metgrid.exe ];then
	printf "\n\t\t......Configure and Compile the WPS code .....\n"
	printf "\n"
	cd $modelpath/WPS
	sed -i 's\=$grib2dir\=$grib2dir</dev/tty\g' configure
	replaceline=$(grep -n ""$"response = <STDIN>" $modelpath/WRF/arch/Config.pl | head -n 1 | cut -d: -f1)
	sed -i ''$replaceline's\$response = <STDIN>\$response = 1\' $modelpath/WPS/arch/Config.pl
	./configure
	./compile
	printf "\n"
	printf "\n"
	printf "\n WPS Code configured and compiled for serial gcc and gfortran architecture option no 1 "
	printf "\n If you wish to configure and compile with other architecture please do manually once this finsihed"
	sleep 10
else
	printf "\n WPS code compiled already\n"
fi

#//////////////////////////////////////////////////////////////////////////////////
printf "\n\t\t\t\t======================================================================"
outmsg8="Downloading WPS Geographic data"
printf "\n\t\t\t\t\t$outmsg8"
printf "\n\t\t\t\t======================================================================\n"
printf "\n"
#=================================================================================
if [ ! -d $modelpath/WPS_GEOG ];then
	cd $modelpath
	wget --no-check-certificate https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz
	tar -xf geog_high_res_mandatory.tar.gz
	rm -rf geog_high_res_mandatory.tar.gz
else
	printf "\nWPS Geographic already downloaded...\n"
fi
#//////////////////////////////////////////////////////////////////////////////////
printf "\n\t\t\t\t======================================================================"
outmsg9="Downloading gfs input data - To Test WRF Model"
printf "\n\t\t\t\t$outmsg9"
printf "\t\t\t\t======================================================================\n"
printf "\n"
#=================================================================================
cd $pathWRF
mkdir INPUT_DATA 2> /dev/null
cd INPUT_DATA
filedate=$(date --date="yesterday" +'%Y%m%d')
if [ ! -f $pathWRF/INPUT_DATA/gfs.t00z.pgrb2.0p50.f000 ];then
	printf "\n $filedate : GFS 3 hourly 00 UTC data downloading for 9 hours\n"
	printf "\n"
	fhr=0
	while [ $fhr -lt 12 ];do
		wget --no-check-certificate https://ftpprd.ncep.noaa.gov/data/nccf/com/gfs/prod/gfs.$filedate/00/atmos/gfs.t00z.pgrb2.0p50.f00$fhr
		fhr=`expr $fhr + 3`
	done
else
	printf "\nGFS 3 hourly 00 UTC data already downloaded...\n"
fi
#//////////////////////////////////////////////////////////////////////////////////
printf "\n\t\t\t\t======================================================================     "
outmsg10="    Editting namelist.wps file and run WRF Pre-processing System (WPS)"
printf "\n\t\t\t\t$outmsg10"
printf "\n\t\t\t\t======================================================================\n"
printf "\n"
printf "\n Once domain is displayed press any key to continue...\n"
sleep 5
printf "\n"
#=================================================================================
cd $modelpath/WPS
echo "&share">namelist.wps
echo " wrf_core = 'ARW',">>namelist.wps
echo " max_dom = 1,">>namelist.wps
echo " start_date = '$(date --date="yesterday" +'%Y-%m-%d')_00:00:00'">>namelist.wps
echo " end_date   = '$(date --date="yesterday" +'%Y-%m-%d')_09:00:00'">>namelist.wps
echo " interval_seconds = 10800">>namelist.wps
echo "/">>namelist.wps
echo "&geogrid">>namelist.wps
echo " parent_id         =   1,">>namelist.wps
echo " parent_grid_ratio =   1,">>namelist.wps
echo " i_parent_start    =   1,">>namelist.wps
echo " j_parent_start    =   1,">>namelist.wps
echo " e_we              =  100,">>namelist.wps
echo " e_sn              =  100,">>namelist.wps
echo " geog_data_res = 'default',">>namelist.wps
echo " dx = 25000,">>namelist.wps
echo " dy = 25000,">>namelist.wps
echo " map_proj  = 'mercator',">>namelist.wps
echo " ref_lat   =  20.00,">>namelist.wps
echo " ref_lon   =  80.00,">>namelist.wps
echo " truelat1  =  30.0,">>namelist.wps
echo " truelat2  =  60.0,">>namelist.wps
echo " stand_lon =  20.0,">>namelist.wps
echo " geog_data_path = '$modelpath/WPS_GEOG/'">>namelist.wps
echo "/">>namelist.wps
echo "&ungrib">>namelist.wps
echo " out_format = 'WPS',">>namelist.wps
echo " prefix = 'FILE',">>namelist.wps
echo "/">>namelist.wps
echo "&metgrid">>namelist.wps
echo " fg_name = 'FILE'">>namelist.wps
echo "/">>namelist.wps

if [ -n "$ncl_status" ];then
	ncl util/plotgrids_new.ncl
fi

printf "\n"
printf "\n Running geogrid.exe to interplote geographical data to define domain grid...\n"
sleep 3
printf "\n"
./geogrid.exe

printf "\n"
printf "\n Running ungrid.exe to extract ungrib data to intermediate files...\n"
sleep 3
printf "\n"
rm -rf Vtable 2> /dev/null
ln -s ungrib/Variable_Tables/Vtable.GFS Vtable
./link_grib.csh $pathWRF/INPUT_DATA/gfs*
./ungrib.exe

printf "\n"
printf "\n Running metgrid.exe to interplote extracted ungrib data to define domain grid...\n"
sleep 3
printf "\n"
./metgrid.exe

#//////////////////////////////////////////////////////////////////////////////////
printf "\n\t\t\t\t======================================================================"
outmsg11="    Editting namelist.input file and run WRF model code"
printf "\n\t\t\t\t$outmsg11"
printf "\n\t\t\t\t======================================================================\n"
printf "\n\tnamelist.input will have default options of physics and dynamics schemes\n"
sleep 5
#=================================================================================
cd $modelpath/WRF/test/em_real

echo  "&time_control">namelist.input
echo  "run_days           = 0,">>namelist.input
echo  "run_hours          = 09,">>namelist.input
echo  "run_minutes        = 0,">>namelist.input
echo  "run_seconds        = 0,">>namelist.input
echo  "start_year         = $(date --date="yesterday" +'%Y'),">>namelist.input
echo  "start_month        = $(date --date="yesterday" +'%m'),">>namelist.input
echo  "start_day          = $(date --date="yesterday" +'%d'),">>namelist.input
echo  "start_hour         = 00,">>namelist.input
echo  "end_year           = $(date --date="yesterday" +'%Y'),">>namelist.input
echo  "end_month          = $(date --date="yesterday" +'%m'),">>namelist.input
echo  "end_day            = $(date --date="yesterday" +'%d'),">>namelist.input
echo  "end_hour           = 09,">>namelist.input
echo  "interval_seconds   = 10800">>namelist.input
echo  "input_from_file    = .true.,">>namelist.input
echo  "history_interval   = 60,">>namelist.input
echo  "frames_per_outfile = 1,">>namelist.input
echo  "restart            = .false.,">>namelist.input
echo  "restart_interval   = 7200,">>namelist.input
echo  "io_form_history    = 2">>namelist.input
echo  "io_form_restart    = 2">>namelist.input
echo  "io_form_input      = 2">>namelist.input
echo  "io_form_boundary   = 2">>namelist.input
echo  "/">>namelist.input

echo  "&domains">>namelist.input
echo  "time_step               = 150,">>namelist.input
echo  "time_step_fract_num     = 0,">>namelist.input
echo  "time_step_fract_den     = 1,">>namelist.input
echo  "max_dom                 = 1,">>namelist.input
echo  "e_we                    = 100,">>namelist.input
echo  "e_sn                    = 100,">>namelist.input
echo  "e_vert                  = 45,">>namelist.input
echo  "dzstretch_s             = 1.1">>namelist.input
echo  "p_top_requested         = 5000,">>namelist.input
echo  "num_metgrid_levels      = 34,">>namelist.input
echo  "num_metgrid_soil_levels = 4,">>namelist.input
echo  "dx                      = 25000,">>namelist.input
echo  "dy                      = 25000,">>namelist.input
echo  "grid_id                 = 1,">>namelist.input
echo  "parent_id               = 0,">>namelist.input
echo  "i_parent_start          = 1,">>namelist.input
echo  "j_parent_start          = 1,">>namelist.input
echo  "parent_grid_ratio       = 1,">>namelist.input
echo  "parent_time_step_ratio  = 1,">>namelist.input
echo  "feedback                = 1,">>namelist.input
echo  "smooth_option           = 0">>namelist.input
echo  "/">>namelist.input

echo  "&physics">>namelist.input
echo  "physics_suite           = 'CONUS'">>namelist.input
echo  "mp_physics              = -1,">>namelist.input
echo  "cu_physics              = -1,">>namelist.input
echo  "ra_lw_physics           = -1,">>namelist.input
echo  "ra_sw_physics           = -1,">>namelist.input
echo  "bl_pbl_physics          = -1,">>namelist.input
echo  "sf_sfclay_physics       = -1,">>namelist.input
echo  "sf_surface_physics      = -1,">>namelist.input
echo  "radt                    = 15,">>namelist.input
echo  "bldt                    = 0,">>namelist.input
echo  "cudt                    = 0,">>namelist.input
echo  "icloud                  = 1,">>namelist.input
echo  "fractional_seaice       = 1,">>namelist.input
echo  "/">>namelist.input

echo  "&fdo">>namelist.input  
echo  "/">>namelist.input

echo  "&dynamics">>namelist.input
echo  "hybrid_opt              = 2,">>namelist.input
echo  "w_damping               = 0,">>namelist.input
echo  "diff_opt                = 2,">>namelist.input
echo  "km_opt                  = 4,">>namelist.input
echo  "diff_6th_opt            = 0,">>namelist.input
echo  "diff_6th_factor         = 0.12,">>namelist.input
echo  "base_temp               = 290.0">>namelist.input
echo  "damp_opt                = 3,">>namelist.input
echo  "zdamp                   = 5000.,">>namelist.input
echo  "dampcoef                = 0.2,">>namelist.input
echo  "khdif                   = 0,">>namelist.input
echo  "kvdif                   = 0,">>namelist.input
echo  "non_hydrostatic         = .true.,">>namelist.input
echo  "moist_adv_opt           = 1,">>namelist.input
echo  "scalar_adv_opt          = 1,">>namelist.input
echo  "gwd_opt                 = 1,">>namelist.input
echo  "/">>namelist.input

echo  "&bdy_control">>namelist.input
echo  "spec_bdy_width          = 5,">>namelist.input
echo  "specified               = .true.">>namelist.input
echo  "/">>namelist.input

echo  "&grib2">>namelist.input
echo  "/">>namelist.input

echo  "&namelist_quilt">>namelist.input
echo  "nio_tasks_per_group = 0,">>namelist.input
echo  "nio_groups = 1,">>namelist.input
echo  "/">>namelist.input

printf "\n"
printf "\n Running real.exe to create intial and boundary conditions...\n"
sleep 3
printf "\n"
ln -sf $modelpath/WPS/met_em* .
./real.exe
outmessage1=$(grep -c "SUCCESS" rsl.error.0000)
if [ $outmessage1 -gt 0 ];then
	printf "\nInital and Boundary conditions created sucessfuly\n"
	echo $(ls *_d01)
	rm -rf rsl.error*
	rm -rf rsl.out*
else
	printf "\nReal Program failed to run, please rectity the error and run again manually\n"
	printf "\n"
	exit
fi

if [ -f wrfinput_d01 ] && [ -f wrfbdy_d01 ];then
	printf "\n"
	printf "\n Running wrf.exe to create forecast for define domain\n"
	sleep 3
	printf "\n"
	./wrf.exe
	outmessage2=$(grep -c "SUCCESS" rsl.error.0000)
	if [ $outmessage2 -gt 0 ];then
		mkdir cd $pathWRF/MODEL_OUTPUT 2> /dev/null
		mv wrfout_d* $pathWRF/MODEL_OUTPUT 2> /dev/null
		printf "\nWRF model completed sucessfuly\n"
		printf "\nWRF model output copied to $pathWRF/MODEL_OUTPUT\n"
	else
		printf "\nWRF Program failed to run, please rectity the error and run again manually\n"
		printf "\n"
		exit
	fi
else
	printf "\nInitial and boundary condition files not present\n"
	printf "\nCreate both the files by running real.exe manually\n"
	printf "\n"
	exit
fi
printf "\n\t\t\t\t[][][][][][][][][][][][][][][][][][][][][][][][][]"
outmsg12="The WRF setup and Test run completed sucessfully"
printf "\n\t\t\t\t$outmsg12"
printf "\n\t\t\t\t[][][][][][][][][][][][][][][][][][][][][][][][][]\n"


