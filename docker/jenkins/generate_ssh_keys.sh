#!/bin/bash

# Define the SSH directory for the jenkins user
JENKINS_SSH_DIR="/home/jenkins/.ssh"

# Create the SSH directory if it doesn't exist
mkdir -p "$JENKINS_SSH_DIR"

# Generate SSH keys if they don't already exist
[ ! -f "$JENKINS_SSH_DIR/ssh_host_rsa_key" ] && ssh-keygen -t rsa -f "$JENKINS_SSH_DIR/ssh_host_rsa_key" -N ''
[ ! -f "$JENKINS_SSH_DIR/ssh_host_ecdsa_key" ] && ssh-keygen -t ecdsa -f "$JENKINS_SSH_DIR/ssh_host_ecdsa_key" -N ''
[ ! -f "$JENKINS_SSH_DIR/ssh_host_ed25519_key" ] && ssh-keygen -t ed25519 -f "$JENKINS_SSH_DIR/ssh_host_ed25519_key" -N ''

# Debug: List the contents of the directory to ensure the keys were created
ls -l "$JENKINS_SSH_DIR"

# Set the correct ownership and permissions for the jenkins user
chown -R jenkins:jenkins "$JENKINS_SSH_DIR"
chmod 700 "$JENKINS_SSH_DIR"
chmod 600 "$JENKINS_SSH_DIR/ssh_host_rsa_key" \
           "$JENKINS_SSH_DIR/ssh_host_ecdsa_key" \
           "$JENKINS_SSH_DIR/ssh_host_ed25519_key"
