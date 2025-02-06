#!/usr/bin/env bash

NETWORK_NAME="network"
SUBNET_NAME="subnet"
VM_NAME="vm"
SSH_KEY_NAME="yc-key"
USER_NAME="ipiris"

yc vpc network create --name "$NETWORK_NAME"

yc vpc subnet create \
  --name "$SUBNET_NAME" \
  --range "10.0.0.0/24" \
  --network-name "$NETWORK_NAME"

ssh-keygen -t ed25519 -f "$SSH_KEY_NAME" -N "" <<< y >/dev/null 2>&1

echo "#cloud-config
users:
  - name: $USER_NAME
    sudo: 'ALL=(ALL) NOPASSWD:ALL'
    groups: sudo
    ssh-authorized-keys:
      - $(cat "$SSH_KEY_NAME.pub")
package_update: true
packages:
  - docker.io
runcmd:
  - [ systemctl, enable, docker ]
  - [ systemctl, start, docker ]
  - [ docker, run, -d, --restart=always, -p, \"80:8080\", \"jmix/jmix-bookstore\" ]" > cloud-conf.yaml

yc compute instance create \
  --name "$VM_NAME" \
  --platform standard-v3 \
  --cores 2 \
  --memory 4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2404-lts-oslogin,size=20,type=network-ssd \
  --network-interface subnet-name="$SUBNET_NAME",nat-ip-version=ipv4 \
  --metadata-from-file user-data=cloud-conf.yaml

VM_IP=$(yc compute instance get --name "$VM_NAME" --format json | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address')

echo "Подключение к виртуальному серверу по SSH:"
echo "ssh -i $SSH_KEY_NAME $USER_NAME@$VM_IP"

echo "Откройте веб-приложение по следующему адресу:"
echo "http://$VM_IP"
