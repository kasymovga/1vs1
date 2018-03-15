1vs1 mod
========

## About

This is game code of [Rexuiz](https://github.com/kasymovga/rexuiz).

## Building

First you need [rmqcc](https://github.com/kasymovga/rmqcc) installed.
After that use make command to build mod.
~~~~
make QCC=/path/to/rmqcc
~~~~

## Installing

Copy `1vs1.dat` and `cl_1vs1-*.pk3` to your ~/.nexuiz/data or ~/.rexuiz/data directory.
Add line at begin of `server.cfg`:
~~~~
exec 1vs1.cfg
~~~~

## How to configure

You can check 1vs1.cfg for available cvars. Most of them not docummented well, sorry.
