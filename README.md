This is a public repository of all of the crazy stuff I mess around with.  In
here, you'll find shell scripts I wrote to carry out certain tasks, ideas that
made me go "Hmmmm....", source code, and whatever else I happened to be messing
with at the time.  Some of you may find it helpful or interesting, some of you
may not.

A subset of this code may not work, so beware.

Good luck.

Contents:

init-killswitch.sh - A hacked /bin/init shell script from Gentoo Linux that is
supposed to go into your initrd when you recompile the kernel.  The idea is
that it asks you for your password twice - the first time as if you'd mistyped
it, the second time as if you'd typed it correctly.  If you gave a different
pre-defined passphrase the first time that's hardcoded in the script it'll
wipe the LUKS headers of your encrypted root volume and wreck the system
(assuming that you created a single LUKS volume and used LVM inside of it).
I haven't tested this yet so be careful.  If you wreck your system I'm not
responsible.

add_jumpstart_pxe_client.sh - A shell script for Solaris that automagically
adds hosts to a Jumpstart server's client list.  Written for Solaris 10/x86.
Will probably work on Solars 10/SPARC as well.

fan_modes.sh - A SYSV-style initscript for manually controlling i8k fans on
Dell laptops.  Itch scratched.

tormirror.sh - A script to automate the updating of a mirror of torproject.org
using rsync.

update_source_trees-1.0.sh - Shell script that automates the process of
updating /usr/src and /usr/ports on OpenBSD machines from CVS.  Can even do
initial checkouts if they don't already exist.

make_iso-1.0.sh - Shell script for Linux that automates the process of making
.iso images to burn to CD-ROM.

burn_dvd - Shell script for Linux that automates the process of burning DVDs,
either from a directory or as a pre-built .iso iamge.  Can even detect and burn
video DVDs if the directory structures are in place.

start-stop-services.sh - An initscript-like script for systemd-enabled laptops.
Goes in /usr/local/sbin, symlinked into /etc/laptop-mode/nolm-ac-st[art,op].
The idea is that whenever laptop mode goes on battery, some services that hit
the disk a lot are shut off to conserve power, and are turned back on when the
system's on AC again.

unmark_dump_to_shaarli.py - Utility written in Python which takes a JSON dump
from an [Unmark](https://github.com/cdevroe/unmark) instance and migrates it
into a new [Shaarli](https://github.com/shaarli/Shaarli) instnace.

diceware.py - An implementation of the [Diceware](http://world.std.com/~reinhold/diceware.html) algorithm for generating more memorable passwords that fit
various parameters.  Requires only a basic install of Python 2 and no third
party modules.  `diceware.py --help` prints the online documentation.

pelican_timed_post.sh - A shell script which implements timed posts in [Pelican](https://blog.getpelican.com/).

