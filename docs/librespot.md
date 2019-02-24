---
title: Librespot
nav_order: 4
layout: default
---
### Librespot

You can turn your sailfish device into a Spotify Connect Player using Librespot. *For as long as Spotify supports the api Librespot uses.*

Librespot is available on [openrepos.net](https://openrepos.net/content/wdehoog/librespot). Stable versions are put on openrepos.net. Development versions are available on the OBS repository. 

### Built on OBS
On [OBS](https://api.merproject.org/package/binaries/home:wdehoog:librespot/librespot?repository=sailfishos_armv7hl) you can find a package to install it on Sailfish. For example (*use correct version*):

```
curl http://repo.merproject.org/obs/home:/wdehoog:/librespot/sailfishos_armv7hl/armv7hl/librespot-sailfish_hutspot_20190110-1.11.1.jolla.armv7hl.rpm -o librespot-sailfish_hutspot_20190110-1.11.1.jolla.armv7hl.rpm

devel-su pkcon install-local librespot-sailfish_hutspot_20190110-1.11.1.jolla.armv7hl.rpm

systemctl --user restart pulseaudio
```
*Note that after installation ```pulseaudio``` really needs to be restarted due to permission to stream audio, see below.*

The package also installs a systemd service file but the ```librespot``` service is not started automatically. To launch it use ```systemctl --user start librespot``` (as user nemo). You can edit ```/etc/default/librespot``` to suit your needs. 
Unfortunately I do not know how to get Librespot service started at boot. See [Issue #11](https://github.com/sailfish-spotify/hutspot/issues/37)

Cargo, the rust builder, cannot download packages on demand on OBS so we need to create a vendor archive. Unfortunately we could not create one that contained all required package versions so the Cargo.toml and Cargo.lock files have been manually edited to 'fix' some dependencies.

Since the kernel on the Oneplus One is old (3.4.67) we needed to patch librespot see [Librespot for kernel < 3.9](https://github.com/librespot-org/librespot/wiki/Compile-librespot-for-kernel-prior-3.9).

Due to the version of Rust available on OBS the latest version of Librespot cannot be build anymore. We forked it to revert a commit related to protobuf see the [repository](https://github.com/sailfish-spotify/librespot). The revert is done in the ```sailfish-hutspot``` branch

### Building locally
Getting cross-compiling working with pulseaudio enabled proved too hard for me so I have also built i on a BananaPi. Should probably work on a RaspberryPi as well. For pulseaudio you also need to install ```libpulse-dev```. 

Building is done with:
```
cargo build --release --features "alsa-backend pulseaudio-backend"
```
There is an Issue about cross compiling with pulseaudio support: [Docker compile with pulseaudio backend fails](https://github.com/librespot-org/librespot/issues/229). At the and a solution is presented but I did not try it.

### Permission to stream audio
To allow LibreSpot to use pulseaudio (and have a non muted sink-input) create /etc/pulse/xpolicy.conf.d/librespot.conf: (as root)

```
[stream]
exe      = librespot
group    = player

```

Restart pulseaudio (or reboot). (as nemo)

```
systemctl --user restart pulseaudio
```

Launching the player is done for example with: (as nemo)

```
librespot -n Sailfish -b 320 -v --backend pulseaudio
```

### Device Discovery
Discovery of the Librespot player is problematic. When used once from a real Spotify app the device shows up in lists. 

Using the commandline options ```--username``` and ```--password``` will make it show up in the list but only for a while. However now the password will be visible in the process list and service status. Only specifying the username will make librespot ask for the password.


If the cache is enabled the credentials will be stored there.
So if you start in once from the command line like:

```
librespot --cache /home/nemo/.cache/librespot --username <USERNAME> -n test 
```
the service can use the cached credentials without showing it in the process or
service lists.

**Note**: from 2019-01-05 on hutspot has a dialog to register your Spotify credentials with Librespot. See the PullDown menu in the Settings page and in the Devices page. It can only work with librespot-master_20180518-1.20.1 or later (since it needs to be able to read the password from stdin).
