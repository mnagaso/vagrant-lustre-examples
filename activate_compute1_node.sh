vagrant ssh mxs -c "sudo scontrol update NodeName=compute1 State=RESUME"
#vagrant ssh mxs -c "sudo scontrol update NodeName=compute1 State=DRAIN Reason=\"Maintenance\" "


vagrant ssh login -c "sinfo -Nel"

