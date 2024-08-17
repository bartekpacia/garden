---
date: 20240816
title: frp (Fast Reverse Proxy) setup guide
description: ngrok but for free, who wouldn't want it?!
---

### Public server

Do this setup on the publicly exposed server.

**/etc/frp/frps.toml**

```toml
bindPort = 7000
```

and then run:

```console
frps -c /etc/frp/frps.toml
```

### Local server

Do this setup on the server behind NAT.

**frpc.toml**

```toml
serverAddr = "104.248.133.139"
serverPort = 7000 # connect to frp server running on this port

[[proxies]]
name = "my-tcp-proxy"
type = "tcp"
localIP = "127.0.0.1"
localPort = 2137 # my server runs on this port
remotePort = 8080 # this port will be exposed on public ser

[webServer]
addr = "127.0.0.1"
port = 7400
user = "admin"
password = "admin"
```

```
frpc -c frpc.toml
```
