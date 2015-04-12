# What is pacmanager?
This is a small shellscript for keeping my arch linux installation clean. It
does that by taking the packages that I want (from pkg-list.sh) and comparing
them to the currently installed packages. This enables me to see all packages
I want to be installed in one file, including comments why I need them.

Pacmanager makes it easy to keep multiple machines packages synchronised, a new
package just needs to be added to pkg-list.sh and it'll be installed on the next
run of `pacmanager.sh -l`. Different packages for different hostnames, for
example because of hardware differences, are also possible.

# License
This piece of software is distributed under the MIT license, see LICENSE for
more details.
