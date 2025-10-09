# =============================================================================
# VIRTUAL MACHINE MODULE - SSH KEY HANDLING
# =============================================================================
# NOTE: SSH keys are now generated in a separate module to prevent redundancy
# This file is kept for reference but does not generate keys
# All VMs receive their SSH public key via the ssh_public_key variable
# =============================================================================

# No SSH key generation here - keys are generated once in the ssh-key-pair module
# and shared across all VMs to maintain a clean, non-redundant architecture
