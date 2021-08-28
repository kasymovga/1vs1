1vs1 mod
========

## About

This is game code of [Rexuiz](https://github.com/kasymovga/rexuiz).

## Building

You need to have [gmqcc](https://github.com/kasymovga/gmqcc) installed.
Use make command to build the mod.
~~~~
make QCC=/path/to/gmqcc
~~~~

## Installing

Copy `1vs1.dat`, `menu.dat`, `1vs1.cfg` and `cl_1vs1-*.pk3` to your ~/.rexuiz/data directory.
Add this line at beginning of `server.cfg`:
~~~~
exec 1vs1.cfg
~~~~
And these lines at beginning of `autoexec.cfg`:
~~~~
exec 1vs1.cfg
exec config.cfg
~~~~

## Configuring

Check out 1vs1.cfg for available cvars. Most of them are not documented very well, it's a work in progress.
