function import_perm_ca() {
  lpass show --field="Public Key" "Shared-CF Perm/Concourse/PermCA" > /tmp/perm-ca.crt
  sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /tmp/perm-ca.crt
}
