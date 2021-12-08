#!/usr/bin/env bash
DOMAIN_ID=sysvolrepl.alt
OTHER_DC=dc1
SSH_PASS=passwd

apt-get install -y osync sshpass

ssh-keygen -t ed25519 -N "" -C "" -f /home/test/.ssh/id_ed25519
sshpass -p "${SSH_PASS}" ssh-copy-id -i /home/test/.ssh/id_ed25519.pub test@${OTHER_DC}

ssh -i /home/test/.ssh/id_ed25519 test@${OTHER_DC} "bash -s sudo -s && sed -i 's/#PermitRootLogin without-password/PermitRootLogin without-password/g' /etc/openssh/sshd_config && systemctl restart sshd &"

sshpass -p "${SSH_PASS}" ssh-copy-id -i /home/test/.ssh/id_ed25519.pub root@${OTHER_DC}

cat > /etc/osync/sync.sh << EOF
#!/usr/bin/env bash
SUDO_EXEC=yes osync.sh --initiator="/var/lib/samba/sysvol/$DOMAIN_ID/" --target="ssh://root@$OTHER_DC:22//var/lib/samba/sysvol/$DOMAIN_ID/" --rsakey=/home/test/.ssh/id_ed25519
ssh -i /home/test/.ssh/id_ed25519 root@$OTHER_DC "bash -s samba-tool ntacl sysvolreset &"
EOF

chmod +x /etc/osync/sync.sh

echo "*/5 * * * * root  /etc/osync/sync.sh" >> /etc/crontab
