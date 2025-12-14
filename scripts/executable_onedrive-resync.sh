sudo systemctl stop --user onedrive
onedrive --sync --resync-auth
sudo systemctl start --user onedrive
