# Vault SSH Signing Demo

### Overview
The signed SSH certificates is the simplest and most powerful in terms of setup complexity and in terms of being platform agnostic. By leveraging Vault's powerful CA capabilities and functionality built into OpenSSH, clients can SSH into target hosts using their own local SSH keys.

- https://developer.hashicorp.com/vault/docs/secrets/ssh/signed-ssh-certificates


### Diagram
<p align="center">
  <img src="./img/vault-ssh-signing.png">
</p>


### Infrastructure Setup (Vault)
```shell
git clone ...
cd ./vault-ssh-signing-demo/tf/vault
terraform init
terraform apply
export VAULT_ADDR=$(terraform output -raw vault_addr)
export VAULT_TOKEN=$(terraform output -raw vault_token)
```

### Vault Setup
```shell
vault status

vault secrets list

vault secrets enable ssh

vault write ssh/config/ca generate_signing_key=true

# standard shell
vault write ssh/roles/demo - <<EOF
{
  "algorithm_signer": "rsa-sha2-256",
  "allow_user_certificates": true,
  "allowed_users": "ubuntu",
  "allowed_extensions": "permit-pty,permit-port-forwarding,permit-user-rc,permit-X11-forwarding,permit-agent-forwarding",
  "default_extensions": {
    "permit-pty": ""
  },
  "key_type": "ca",
  "default_user": "ubuntu",
  "ttl": "30m"
}
EOF

# force command
vault write ssh/roles/forcecmd - <<EOF
{
  "algorithm_signer": "rsa-sha2-256",
  "allow_user_certificates": true,
  "allowed_users": "ubuntu",
  "allowed_extensions": "permit-pty,permit-port-forwarding,permit-user-rc,permit-X11-forwarding,permit-agent-forwarding",
  "allowed_critical_options": "force-command",
  "default_critical_options": {
    "force-command": "cat /var/log/example.log"
  },
  "key_type": "ca",
  "default_user": "ubuntu",
  "ttl": "30m"
}
EOF
```

### Infrastructure Setup (VM)
```shell
cd ..
terraform init
terraform apply -var="vault_addr=$VAULT_ADDR"
export REMOTE=$(terraform output -raw demo_ip)
```

### Vault Usage
```shell
ssh-keygen -t rsa -C "user@example.com" -f $HOME/.ssh/id_rsa

# manual
vault write -field=signed_key ssh/sign/demo public_key=@$HOME/.ssh/id_rsa.pub > $HOME/.ssh/id_rsa-cert1.pub

ssh-keygen -Lf ~/.ssh/id_rsa-cert1.pub

ssh -i $HOME/.ssh/id_rsa-cert1.pub -i $HOME/.ssh/id_rsa ubuntu@$REMOTE

# all in one
vault ssh -mode=ca -role=demo ubuntu@$REMOTE
vault ssh -mode=ca -role=forcecmd ubuntu@$REMOTE
```

### Cleanup
```shell
terraform destroy -var="vault_addr=$VAULT_ADDR"
terraform -chdir=vault destroy
```
