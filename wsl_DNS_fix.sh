if ! grep -q "Add DNS entry" ~/.zprofile; then
  echo "Adding DNS entries"
  echo "# Add DNS entry for Windows host
if ! \$(cat /etc/hosts | grep -q 'winhost'); then
  echo 'Adding DNS entry for Windows host in /etc/hosts'
  echo '\n# Windows host - added via ~/.zprofile' | sudo tee -a /etc/hosts
  echo -e \"\$(grep nameserver /etc/resolv.conf | awk '{print \$2, \"   winhost\"}')\" | sudo tee -a /etc/hosts
fi


if ! \$(cat /etc/resolv.conf | grep -q '.zprofile'); then
  echo 'Adding DNS entry in /etc/resolv.conf'
  echo '\n# DNS entry - added via ~/.zprofile' | sudo tee -a /etc/resolv.conf
  echo \"nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 8.8.8.8
nameserver 2606:4700:4700::1111
nameserver 2606:4700:4700::1001
nameserver 2606:4700:4700::1112
nameserver 2606:4700:4700::1002
nameserver 2001:67c:2b0::4
nameserver 2001:67c:2b0::6\" | sudo tee -a /etc/resolv.conf
fi" | tee -a ~/.profile | tee -a ~/.zprofile
fi
