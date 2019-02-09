---
title: Installation
nav_order: 2
layout: default
---
The package of hutspot can be installed or downloaded from my [OBS repository]( https://api.merproject.org/package/binaries/home:wdehoog:hutspot/hutspot?repository=sailfish_latest_armv7hl). 

### Install from rpm file
Download the latest rpm and install it for example with:

```
curl http://repo.merproject.org/obs/home:/wdehoog:/hutspot/sailfish_latest_armv7hl/armv7hl/hutspot-<version>.armv7hl.rpm -o hutspot-<version>.armv7hl.rpm

devel-su pkcon install-local hutspot-<version>.armv7hl.rpm
```


### Install from repository
To add this repository:

```
devel-su ssu ar wdehoog-hutspot http://repo.merproject.org/obs/home:/wdehoog:/hutspot/sailfish_latest_armv7hl/
```

Then install with

```
devel-su pkcon refresh wdehoog-hutspot
devel-su pkcon install hutspot
```

### Uninstall

```
devel-su pkcon remove hutspot
```

Remove the repository
```
devel-su ssu dr wdehoog-hutspot
devel-su ssu rr wdehoog-hutspot
```

### Build it yourself
See the repository at [github](https://github.com/sailfish-spotify/hutspot).

