<p align="center">
<img src="https://github.com/martinkubecka/quickToRelay/blob/main/images/logo.png" alt="Logo">
<p align="center"><b>Automate the process of setting up a Middle/Guard Tor Relay on Debian.</b><br>
</p>

---
## :onion: Description

***quickToRelay*** is an easy-to-follow interactive script written in bash. Its main goal is to automate the process of setting up a Middle/Guard Tor Relay on Debian. This script allows you to:
- configure nickname, email an ORPort
- configure bandwidth and accounting limits for relay traffic
- configure open ports with *ufw*
- enable automatic updates
- configure Tor project's repository
- install Tor and Tor Debian keyring
- install and configure *Nyx* for monitoring 

---
## :card_file_box: Pre-requisites

- [Debian](https://www.debian.org/) (latest release recommended)

> Do not forget to open port (ORPort) in your firewall, if you are running your relay in a VPS with its own firewall rules management.

---
## :satellite: Usage 

Run the command bellow and follow the instructions.

```
wget -q https://raw.githubusercontent.com/martinkubecka/quickToRelay/main/quickToRelay.sh ; chmod +x quickToRelay.sh ; sudo ./quickToRelay.sh
```

![](https://github.com/martinkubecka/quickToRelay/blob/main/images/quickToRelay.gif)

---
## :mega: Acknowledgements

- Tor's Relay Operations documentation : https://community.torproject.org/relay/
- Nyx : https://nyx.torproject.org/#home
- Debian's ufw documentation : https://wiki.debian.org/Uncomplicated%20Firewall%20%28ufw%29