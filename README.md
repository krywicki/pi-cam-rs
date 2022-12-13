# raspberrypi-cam-rust

Raspberry-PI 4 camera streaming & image recognition in rust.

## Setup

## SSH Settings

If ssh'ing into the raspberry pi, the following settings will help keep ssh connections alive and avoid broken pipes
during heavy process usage on the pi.


**Raspberry PI SSHD Settings**

- Set the following options in  `/etc/ssh/sshd_config`
	- note: This results in server-side connection closure after 5 mins (60 secs * 5)

	```bash
	TCPKeepAlive no
	ClientAliveInterval 60
	ClientAliveCountMax 5
	```

- Restart sshd
	```bash
	sudo systemctl reload sshd
	```
**Client SSH Settings**

- Modify raspberry pi ssh config entry in `$HOME/.ssh/config`
	- note: This results in client-side connection closure after 5 mins (60 secs * 5)

	```ssh
	Host my-raspberry-pi
		# ... other config options
		ServerAliveInterval 60
		ServerAliveCountMax 5
		TCPKeepAlive no
	```
