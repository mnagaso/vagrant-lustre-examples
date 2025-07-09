#!/bin/bash
# =============================================================================
# Script Validation Utility
# =============================================================================
# PURPOSE: Validates that all required scripts exist and have proper syntax
# USAGE: Run manually to check script integrity before deployment
# STATUS: Utility script - not used by Vagrantfile
# =============================================================================

# Validate that all required scripts exist

SCRIPT_DIR="$(dirname "$0")"
REQUIRED_SCRIPTS=(
    "create_file_hosts.sh"
    "create_repo.sh"
    "install_packages_common.sh"
    "install_packages_kernel_patched.sh"
    "install_packages_server_ldiskfs.sh"
    "install_packages_server_zfs.sh"
    "install_packages_client.sh"
    "disable_selinux.sh"
    "configure_lnet.sh"
    "configure_lustre_server_mgs_mds.sh"
    "configure_lustre_server_oss_zfs.sh"
    "configure_lustre_client.sh"
    "check_kernel_version.sh"
    "install_packages_test_suite_server.sh"
    "install_packages_test_suite_client.sh"
    "start_lustre_server.sh"
    "install_slurm_basic.sh"
    "create_slurm_environment.sh"
    "configure_login_node.sh"
    "create_job_script.sh"
    "create_user_dirs.sh"
    "install_open_ondemand.sh"
    "configure_open_ondemand.sh"
    "configure_ssh_for_ood.sh"
    "install_keycloak.sh"
    "configure_keycloak_oidc.sh"
)

echo "Validating script files..."
MISSING_SCRIPTS=()

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$script" ]; then
        MISSING_SCRIPTS+=("$script")
        echo "❌ Missing: $script"
    elif [ ! -x "$SCRIPT_DIR/$script" ]; then
        echo "⚠️  Not executable: $script"
        chmod +x "$SCRIPT_DIR/$script"
        echo "   Fixed permissions for $script"
    else
        echo "✅ OK: $script"
    fi
done

if [ ${#MISSING_SCRIPTS[@]} -eq 0 ]; then
    echo ""
    echo "🎉 All required scripts are present and executable!"
    exit 0
else
    echo ""
    echo "❌ Missing ${#MISSING_SCRIPTS[@]} script(s). Please create them before running Vagrant."
    exit 1
fi
