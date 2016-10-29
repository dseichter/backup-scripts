#!/bin/bash
#### Description: Backup all virtual machines of an OpenNebula installation version 4.14.2 
####
#### Written by: Daniel Seichter <daniel.seichter@dseichter.de>
#### Created on: Sat, 29th Oct 2016

# Step1: iterate through all virtual machines by parsing the output table of onevm list
for vmid in $(/usr/bin/onevm list | awk 'BEGIN{n=2}NR<=n{next}1' | cut -b 1-7); do

    # set the need variables
    machine=$vmid
    backup=$machine_backup
    destination=/mnt/$backup # <-- set the destination

    if [ $(/usr/bin/onevm show ${machine} | grep LCM_STATE | cut -d ":" -f 2) == "RUNNING" ]; then
        
        # Invoke backup tool by opennebula
        echo "Start saving image using disk-saveas"
        /usr/bin/onevm disk-saveas ${machine} 0 ${backup} >> /dev/null

        # get the status of the newly generated image
        status=$(/usr/bin/oneimage show ${backup} | grep STATE | cut -d ":" -f 2)
        # Wait for the backup to finish
        while [ ! ${status} == "rdy" ]
        do
          # get the status of newly generate image as long as the status is not "rdy"
          status=$(/usr/bin/oneimage show ${backup} | grep STATE | cut -d ":" -f 2)
          echo "Current status of image $backup is: $status"
        done

        # Output the path for snapshot
        imagefile=$(/usr/bin/oneimage show ${backup} | grep SOURCE | cut -d ":" -f 2)
        
        echo "The image $imagefile will now be copied"
            
        # we do a simple copy of the imagefile file to the backup location    
        cp $imagefile $destination

        # at least, we delete the image from open nebula again
        /usr/bin/oneimage delete $backup
    
    fi

done
