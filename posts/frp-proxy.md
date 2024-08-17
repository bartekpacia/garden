---
date: 20240818
title: frp (Fast Reverse Proxy) setup guide
description: ngrok but for free, who wouldn't want it?!
---

## Intro

(feel free too skip it if you're here just for the config)

In recent weeks, I've been spending a lot of time building on the backend (and
like it a lot!). After the initial spike where I was running stuff on my laptop,
time came to actually the server out to the web, so my friend's frontend (hosted
on Vercel) will be able to hit the backend.

Ah, the age old question, once again. How to expose my thing to the world?

A minute or two to get the container up and running on Google Cloud Run seems to
not be _that long_, but compared to ~5 seconds it takes to rebuild my server
image locally, it's night a night and day difference.

So, I reached for the old, good ngrok – or is it? Well, last time I used it a
few years ago, it was this cute little tool. Now it seems to have grown into
something much bigger, that I don't care enough about to understand, and gives
me low-key enshittification vibes. Also, I ain't paying $10/month for stable IP
address just to tunnel public traffic to my laptop.

## Meet frp

I went on the lookout for a free, self-hosted alternatives, and quickly found
[the `frp` project][frp] (Fast Reverse Proxy). It was exactly what I needed. 

To get started, download the latest frp release for your machine from
https://github.com/fatedier/frp/releases. Once you unzip, you should find two
binaries in there:
- `frps` - Fast Reverse Proxy server
- `frpc` - Fast Reverse Proxy client

> It was mildly annoying to me is that neither `frps` nor `frpc` are available
on apt and Homebrew. I'll try to get frp on Homebrew when I'll be sufficiently
bored and free.

## Config

Armed with knowledge from `frp`'s README and some
[two](https://gabrieltanner.org/blog/port-forwarding-frp)
[blogposts](https://cprimozic.net/notes/posts/self-hosted-ngrok-alternative), I
started configuring it on my VPS with stable IP.

### On the public server

Do this setup on the server that has a stable IP address. For simplicity, I
decided to keep things in my user's `$HOME`:

```
~
├── frp/
│   ├── frps
│   └── frps.toml
│   └── frps.service
```

`frps` is the binary, and `frps.toml` is literally a single line:

```
bindPort = 7000
```

This is `frps.service`:

```
[Unit]
Description=Fast Reverse Proxy server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=%h/frp/frps -c %h/frp/frps.toml
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=default.target
```

**Heads up**: to be able to use `%h` in systemd unit file – which expands to
`/home/charlie` (assuming your user is `charlie`) – this service has to [run as
a user service, not a system one][systemd_user_vs_system_service]. Also, you
have to enable lingering (`$ loginctl enable-linger`) to [avoid our service
being killed on user logout][systemd_linger].

With that out of the way, let's register the service in systemd:

```
cp ~/.frp/frps.service ~/.config/systemd/user
```

Enable it to always run on startup:

```
systemctl --user enable frps.service
```

And start it right now:

```console
systemctl --user start frps.service
```

> Even though I'm not a fan of systemd, I have a slight preference for it over
> containers when it comes to self hosting, so this config is systemd-based. The
> simpler, the better.

### On the local server

Do this setup on the server that cannot be reached from the public internet
(e.g. because of being behind NAT or firewalls) – such as your laptop.

**frpc.toml**

I put this file in `~/.config/frp`.

```toml
serverAddr = "106.248.27.132"
serverPort = 7000 # connect to frp server running on this port

[[proxies]]
name = "my-tcp-proxy"
type = "tcp"
localIP = "127.0.0.1" # my server runs on localhost
localPort = 2137 # my server runs on this port on localhost
remotePort = 8080 # this port will be exposed on public server
```

Then run the frp client – `frpc` – and specify the config file:

```console
frpc -c ~/.config/frp/frpc.toml
```

Now open a new terminal tab and run your server, listening on the port you
specified in `fprc.toml` (2137 in our case). If you don't have any backend at
hand, you can use [Eli Bendersky's static fileserver][eli_fileserver]:

```console
go run github.com/eliben/static-server@latest --addr localhost:2137
```

### Test it

Assuming IP of your server is 106.248.27.132, open `http://106.248.27.132:8080`
in the browser.

You should be able to see contents of the directory you run `static-server` in.

### Wrapping up

The whole thing is hosted on the cheapest $5/month VPS from DigitalOcean, and it
works perfectly. Now, whenever I start developing my backend locally, but want
to also have it exosed to the grand World Wide Web, I use `frpc`.

I didn't bother to set up TLS, so it's only `http` for now, but that's fine for
my use case. I might get to it in the future.

[systemd_user_vs_system_service]: https://superuser.com/q/853717/721371
[systemd_linger]: https://unix.stackexchange.com/q/521538/417321
[eli_fileserver]: https://eli.thegreenplace.net/2023/static-server-an-http-server-in-go-for-static-content
