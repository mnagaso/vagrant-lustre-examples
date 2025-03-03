if ! vagrant plugin list | grep -q vagrant-scp; then
    echo "vagrant-scp plugin not installed. Installing now..."
    vagrant plugin install vagrant-scp
fi

vagrant scp ./slurm_update_config.sh mxs:~/
vagrant scp ./slurm_update_config.sh oss:~/
vagrant scp ./slurm_update_config.sh login:~/
vagrant scp ./slurm_update_config.sh compute1:~/

# fix permission
vagrant ssh mxs -c "sudo chmod 755 /var/run/munge"
vagrant ssh oss -c "sudo chmod 755 /var/run/munge"
vagrant ssh login -c "sudo chmod 755 /var/run/munge"
vagrant ssh compute1 -c "sudo chmod 755 /var/run/munge"

# First on mxs (controller)
vagrant ssh mxs -c "sudo bash /home/vagrant/slurm_update_config.sh"

# Then on each compute node (in new terminal tabs/windows)
vagrant ssh oss -c "sudo bash /home/vagrant/slurm_update_config.sh"
vagrant ssh login -c "sudo bash /home/vagrant/slurm_update_config.sh"
vagrant ssh compute1 -c "sudo bash /home/vagrant/slurm_update_config.sh"
