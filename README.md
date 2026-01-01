# AUTOwgIP
A bash script that automatically updates Wireguard client endpoint IP for every container in proxmox. Useful for servers with dynamic public ip.

# Install:
<pre>
git clone https://github.com/trfaa001/AUTOwgIP
cd AUTOwgIP
chmod +x install.sh
./install.sh
</pre>
or
<pre>
git clone https://github.com/trfaa001/AUTOwgIP && cd AUTOwgIP && chmod +x install.sh && ./install.sh
</pre>

# Function and limitations

Script function:
1. Check if the IP has changed
2. Go into every container and change the config file
3. Sync the Wireguard config

Limitations of the script:
* Wireguard need to be preconfigured in the container.