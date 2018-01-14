#!/bin/bash
set -v -x	
set -e
#Declare some Arrays, might not be needed.
declare -a Pics
declare -a ivideo
declare -x uplloc
declare -x Name
declare -x gifup
declare -a texts
declare -a dir
declare -a Screens
declare -a iPics


#Location of Upload.py script
uplloc="/path/to/jerkingupload.py"
#Location of Template
Template="/path/to/Template.txt"

for i in "$@"; do
	if [ -d "$i" ]
		then
			echo "$i Is a directory"
			dir+=("$i")
			Name=$(basename "$i")
		else
			if [ "${i: -4}" = ".txt" ]
						then
							texts+=( "$(cat "$i")" )
							echo "Recognized as .txt, added to texts."
				else
				test2=$(identify "$i")
				echo "$test2"
					if [ "$test2" == "" ]
					then
						echo "It looks like $i is not a directory, picture file or a text file. Aborting since DAFUQ?"
						exit
						else
						echo "$i is a picture"
						Pics+=("$i")
					fi
			fi		
	fi	
done

if [ ${#dir[@]} -gt 1 ]; then
	echo "More than one folder, i don't know what to do?"
	exit
fi

echo "$Name"
echo "${dir[0]}"


#Find Directories
dirfind ()
{
for i in "$*"/*; do
	if [ -d "$i" ]
		then
			dir+=("$i")
			dirfind "$i"
	fi
done
}		
dirfind "${dir[0]}"
echo "Folders i've collected: ${#dir[@]}"
echo "${dir[@]}"

#Count amont of video files in Dir
countstuff ()
{
for i in "$*"/*; do
	if [ -d "$i" ]
		then 
			echo ""
		else
			test=$(mediainfo --Inform="General;%Duration/String3%" "$i")
			if [ ! -z "$test" ]
				then
					ivideo+=("$i")
			fi
	fi
done
}

for i in "${dir[@]}"; do
	countstuff "$i"
done

echo "${#ivideo[@]} video files found"
echo "${ivideo[@]}"

echo ""
mkdir -p "$Name/Screens"
#make screens for video files
for i in "${ivideo[@]}"; do
	videoname=$(basename "$i")
	echo "$videoname"
	vcs -n 21 -o "$Name/Screens/$videoname".jpg "$i" && S=("$(python $uplloc "$Name/Screens/$videoname".jpg)")
	Screens+=$( printf "[thumb]$S[/thumb]" )
	echo "Uploaded $i"
done

echo "${Screens[@]}"

#Upload pictures to jerking and save URL for presentation
echo "I have ${#Pics[@]} Pictures"
for i in "${Pics[@]}"; do
	iPics+=("$(python $uplloc "$i")")
	echo "Uploaded $i"
done


#Here i make a presentation based on a templete that i saved as a .txt, and fill it with the metadata.
:> "template for $Name"
awk -v CREENS1="$Screens" -v TORRENT="Pack of $Name in ${#ivideo[@]} videos" -v PIC0="${iPics[0]}" -v PIC1="${iPics[1]}" -v DESCRI1="${texts[0]}" -v DESCRI2="${texts[1]}" -v ACTRE="$Name" -v SCENES="${#ivideo[@]}" -v DESCRI3="${texts[2]}" '{
    sub(/CREENS1/, CREENS1);
    sub(/PIC1/, PIC1);
    sub(/PIC0/, PIC0);
    sub(/DESCRI1/, DESCRI1);
    sub(/DESCRI2/, DESCRI2);
	sub(/ACTRE/, ACTRE);
	sub(/SCENES/, SCENES);
	sub(/DESCRI3/, DESCRI3);
	sub(/TORRENT/, TORRENT);
    print;
}' "$Template" > "template for $Name"


if [ "${#Pics[@]}" -gt 2 ]
	then
		echo "More than 2 pictures Added"
		echo "${Pics[@]:2}"
		for i in "${Pics[@]:2}"; do
			echo "$i" >> "template for $Name"
			
		done
	else
		echo ""
fi
if [ "${#texts[@]}" -gt 2 ]
	then
		echo "More than 2 text files Added"
		for i in "${texts[@]:2}"; do
			echo "$i" >> "template for $Name"
			
		done
fi



#Makes the torrent; one for emp and one for PB. Remove a line if needed.
transmission-create -s 512 -o "$Name\\ EMP.torrent" "${dir[0]}" #For EMP
transmission-create -s 256 -o "$Name\\ PB.torrent" "${dir[0]}" #For PB

echo "Done"
exit