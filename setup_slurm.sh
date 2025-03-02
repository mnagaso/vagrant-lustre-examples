# First on mxs (controller)
vagrant ssh mxs -c "sudo bash /home/vagrant/slurm_update_config.sh"

# Then on each compute node (in new terminal tabs/windows)
vagrant ssh oss -c "sudo bash /home/vagrant/slurm_update_config.sh"
vagrant ssh login -c "sudo bash /home/vagrant/slurm_update_config.sh" 
vagrant ssh compute1 -c "sudo bash /home/vagrant/slurm_update_config.sh"
