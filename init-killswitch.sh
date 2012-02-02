#!/bin/ash
# =====================================
# | WARNING:                          |
# |______USE AT YOUR OWN RISK!________|
#
# [[SECURITY_System_Encryption_DM-Crypt_with_LUKS]]
#                                 
# Arguments:
#   init script supports the following:
#     standard: 
#       * root=<device>          root device (required).
#       * ro                     mount root read only.
#
#     init specific:       
#      * ikmap=<kmap>[:<font>]      Load kmap and font(optional).
#      * is2                        Enables suspend2 support(required for
#					suspend2 users).
#      * rescue                     Drops you into a minimal shell
#      * iswap=<device>             swap device(eg:/dev/sda2) (required for
#					suspend2 users).
#      * ichkpt=<n>                 Interrupts init and drops to shell.
#      * ikey_root=<mode>:<device>:</path/to/file>  
#      * ikey_swap=<mode>:<device>:</path/to/file>
#      
#                      
# == About key files ==
#        For partitions that are encrypted with a key, you must set 'ikey_root'
#		and/or 'ikey_swap' properly, otherwise you'll be asked for the
#		passphrase.
#       This information is then used to obtain each key file from the
#		specified removable media. 
#
#       <mode>           - defines how the init script shall treat the supplied
#				keyfile(see below). 
#       <device>         - the device that will be assigned to the removable
#				media.
#       </path/to/file>  - full path to file inside the removable media.
#
#       Supported modes:
#       gpg              - indicates keyfile is gpg-protected
#       none             - indicates keyfile is regular file
#
#        == Notes on keys ==
#         o gpg encrypted key file --> o It'll be decrypted and piped into
#         				 cryptsetup as if it were a passphrase. 
#                                      o Works if and only if you did the same
#                                        when you luksFormated the partition. 
#                                        If for example, you decrypt the gpg
#                                        file and then use it as positional
#					 argument to luksFormat or luksAddKey,
#					 then it'll fail because the new-line
#					 character('\n') will not be ignored.
#                                        If you remove the new-line char from
#                                        the key...
#
#                    'cat key | tr -d '\n' > cleanKey' and then use 'cleanKey'
#
#                                        as the --key-file argument it will
#                                        work.   
#
#         o regular key file       --> o It'll be passed to cryptsetup as
#         				 --key-file
#
# == Suspend2 ==  
#        Suspend2 users should always boot with 'is2', special care must be
#        taken to ensure that the swap device always has the same major/minor
#        numbers within the initramfs as well as your running system. (see
#        kernel doc: power/swsusp-dmcrypt.txt)
#
#        To achieve this, the init script will always decrypt your swap
#        partition first whether you're resuming from hibernation or not.
#         
#        IMPORTANT:
#        There are certain scenarios that can lead to data loss or corruption,
#        you should read suspend2 documentation resources, in particular:
#                 [1] - suspend2.net -> HOWTO -> Avoiding data loss
#                 [2] - kernel doc: power/suspend2.txt
#   
#        WARNING! -- DATA LOSS -- !WARNING
#        * Always boot with is2 argument, even if you're not resuming from
#          hibernation.
#        * Attempting to resume with different kernel(eg: recompiled kernel):
#             If the second kernel has suspend2 support:
#             You will get a BIG FAT WARNING about version mismatch, 
#             Press 'Shift' to reboot, DO NOT CONTINUE.
#             Then boot with noresume2.
#             Resuming with a different kernel will corrupt/crash the system
#             and might cause filesystem damage. (See: Suspend2.net FAQ 5.13)
#        * Booting a kernel with noresume2 (or a non suspend2 kernel) and then
#          resuming from a previous image.
#        * Mounting (even as ro) partitions that were mounted when you
#          suspended(hibernated), and then trying to resume.
#
#         Use the hibernate script to control unmounting partitions. 
#       
#         DANGER: Back up your data!
# 
#        == Kernel parameters example ==
#        o) Partition(s): root -- Key: regular passphrase
#           root=/dev/sda3 ikmap=es-cp850_i686.bin    
#        o) Partition(s): root -- Key: regular passphrase -- Extra: fbsplash
#           root=/dev/sda3 vga=0x318 video=vesafb:mtrr,ywrap \ 
#           splash=verbose,theme:livecd-2006.0 quiet CONSOLE=/dev/tty1
#        o) Partition(s): root -- Key: regular keyfile on usb stick
#           root=/dev/sda3 ikey_root=none:/dev/sdb1:/path/to/keyfile
#        o) Partition(s): root -- Key: gpg encrypted key on usb stick
#           root=/dev/sda3 ikey_root=gpg:/dev/sdb1:/path/to/file
#        o) Partition(s): swap root -- Suspend2 noresume2 --
#           Key(s): gpg, regular keyfile
#           root=/dev/sda3 is2 noresume2 iswap=/dev/sda2
#           ikey_root=none:/dev/sdb1:/path/to/rootkey \
#           ikey_swap=gpg:/dev/sdb1:/path/to/swapkey.gpg
#        o) Partition: swap -- Suspend2 resume2(resuming from hibernation) --
#           Key: regular passphrase
#           is2 iswap=/dev/sda2 resume2=swap:/dev/mapper/swap
#        o) Partition: swap -- Suspend2 resume2 -- Key: gpg protected key on
#           usb stick
#           is2 iswap=/dev/sda2 resume2=swap:/dev/mapper/swap \
#           ikey_swap=gpg:/dev/sdb1:/path/to/swapkey.gpg 
#
# == Modules == 	
# If you need to load modules, create the groups you need in /etc/modules/
# (inside initramfs /), each file should be a list of the modules, and each
# file name denotes the step in the init where they should be loaded.
#
# Supported groups:
#	* boot           -  boot time modules loaded but not removed.
#	* suspend2       -  suspend2 module (not required anymore?).
#	* remdev         -  modules required to access removable device
#	* gpg            -  modules required to access gpg protected file.
#
#	o The modules should exist on /lib/modules/`uname -r`/, like in your
#	  system.
#       o Your kernel has to support module unloading for rmmod to work.
#
# BUGS/KNOWN ISSUES:
#     (b0) fbsplash: when setting the splash mode from silent to verbose,
#                 verbose image is not painted and text is not visible.
#                 WORKAROUND: boot with verbose instead.
#
#     (b1) Redirect ugly hotplug messages about usb-stick to /dev/null, it can
#     be very annoying if they happen to appear when user is asked for passphrase.
#     WORKAROUND: sleep 5 in main() before calling do_work() 
#
#     (ki0) The length of init arguments should be reduced.
#     Users with a long kernel parameter list might find init (or the system)
#     not working as expected because some arguments where stripped. 
#     "... The length of complete kernel parameters list is limited, the limit
#     depends on the architecture, and it's defined in include/asm/setup.sh as
#     COMMAND_LINE_SIZE. ..." (kernel doc: kernel-parameters.txt) 
#
#     (ki1) If the same removable device is used for swap and root
#     (99.9% users), it gets mounted twice.
#
#     (ki2) some suspend2 users might find annoying being asked for passphrases
#     twice(swap, root) when booting with noresume2, possible solution (beside
#     using regular keyfiles) could be having a single gpg encrypted file that
#     contains the two keys.  At boot, init asks for the passphrase to decrypt
#     the file, stores it in a variable, then when the keys are needed to
#     decrypt the partitions, init would use the passphrase to decrypt the gpg
#     file and select the right key for the partition, like this:
#
#     <n> = line number of the key for partition.
#     echo "${gpg_passphrase}" | gpg --no-tty --passphrase-fd 0 \
#     --decrypt keys.gpg | head -n <n> | tail -n 1 
#
#     the obtained key can then be used with cryptsetup to decrypt the
#     partition.
#
#     Caveats:
#           o) passphrase stored in bash variable, no idea how safe this is. 
#
# ToDo:
#     * lvm support
#     * raid support	
#     * steganography support -- retrieve hidden key(s)
#     * PKCS#11 cryptographic token support
#     * suspend2 filewriter support
#
# Contact:
#   o) Bugs, critics, feedback, improvements --> reikinio at gmail dot com
#   o) Flames                                --> /dev/null
#
# History: (y/m/d)
# ------------------
# 2006.08.24 - Federico Zagarzazu
#    Fix: call splash_setup() if fbsplash args exist   
# 2006.08.06 - Federico Zagarzazu
#    Released.
# 2006.08.06 - Federico Zagarzazu
#    Fixed: /dev/device-mapper /dev/mapper/control issue 
#           otherwise it fails on my amd64 system
# 2006.08.04 - Federico Zagarzazu
#    Bug fixes, several improvements.
#    Test phase finished.
# 2006.06.20 - Federico Zagarzazu
#    Written.
# 
# Thank you! 
# ---------------------------------------------------------------
# o Alon Bar-Lev [http://wiki.suspend2.net/EncryptedSwapAndRoot]
#   I stole ideas, general structure and entire functions from his init script.
# o nix
# o Andreas Steinmetz [kernel doc: power/swsusp-dmcrypt.txt]
#
#  ___________________________________
# | WARNING:			      |
# |______USE AT YOUR OWN RISK!________|   

# user defined variables
uv_init=/sbin/init           # init to execute after switching to real root
uv_root_mapping=root         # self descriptive
uv_swap_mapping=swap	     # ^^
uv_check_env=0               # test if busybox applets exist 

# default values(don't edit)          
gv_active_splashutil=0
gv_splash_silent=0
gv_root_mode=rw
gv_shell_checkpoint=0

# functions
die()
{
        local lv_msg="$1"
	umount -n /mnt 2>/dev/null
        [ "${gv_splash_silent}" -eq 1 ] && splash_verbose
        echo "${lv_msg}"
        echo 
        #echo "Dropping you into a minimal shell..."
        #exec /bin/ash
        echo "Unable to mount root filesystem.  Shutting down."
        exec /sbin/halt
}

bin_exist()
{
	[ ! -e "/bin/${1}" ] && [ ! -e "/sbin/${1}" ] && die "Error: ${2} ${1} not found."
}

check_busybox_applets()
{
	if [ ! -e "/etc/applets" ]; then
		echo "Warning: Cannot check if BusyBox's applets exist(/etc/applets missing)"
	else
		for i in `cat /etc/applets`; do
			bin_exist ${i} "BusyBox applet" 
		done
	fi
}

rmmod_group() {
        local lv_group="$1"
        local lv_invert
        local lv_mod

        if [ -f "/etc/modules/${lv_group}" ]; then
                for mod in `cat "/etc/modules/${lv_group}"`; do
                        invert="${lv_mod} ${lv_invert}"
                done

                for mod in ${lv_invert}; do
                        #
                        # There are some modules that cannot
                        # be unloaded
                        #
                        if [ "${lv_mod}" != "unix" ]; then
                                rmmod "`echo "${lv_mod}" | sed 's/-/_/g'`"
                        fi
                done
        fi
}

modprobe_group() {
        local lv_group="$1"
        local lv_mod

        if [ -f "/etc/modules/${lv_group}" ]; then
                for mod in `cat "/etc/modules/${lv_group}"`; do
                        modprobe "${lv_mod}" > /dev/null 2>&1
                done
        fi
}

#killallwait() { # no use for it yet
#        local lv_p="$1"
#
#        while killall -q -3 "${lv_p}"; do
#                sleep 1
#        done
#}

splash_command() {
        local lv_cmd="$1"

        if [ ${gv_active_splashutil} != 0 ]; then
                echo "$lv_cmd" > /lib/splash/cache/.splash
        fi
}

splash_verbose() {
        splash_command "set mode verbose" 
}

splash_silent() {
        splash_command "set mode silent"
}

splash_message() {
        local lv_msg="$1"

        splash_command "set message ${lv_msg}"
        splash_command "repaint"
}

splash_setup() {
	[ "$uv_check_env" -eq 1 ] && bin_exist "splash_util.static" "--"
        if [ -n "${gv_splash_console}" ]; then
                exec < "${gv_splash_console}" > "${gv_splash_console}" 2>&1
        fi
        [ -e /lib/splash/cache ] || mkdir -p /lib/splash/cache
        [ -e /lib/splash/cache/.splash ] || mknod /lib/splash/cache/.splash p
        splash_util.static --daemon "--theme=${gv_splash_theme}"
        gv_active_splashutil=1
}

splash_daemon_stop() {
	if [ "${gv_active_splashutil}" -ne 0 ]; then
                splash_command "exit"
                gv_active_splashutil=0
        fi
}

shell_checkpoint() {
        local lv_level=$1

        if [ "${gv_shell_checkpoint}" -eq "${lv_level}" ]; then
                splash_verbose
		echo "Checkpoint ${lv_level}" 
                exec /bin/ash
        fi
}

suspend2_resume() {
        [ "${gv_splash_silent}" -eq 1 ] && splash_message "Resuming..."
        splash_daemon_stop

        modprobe_group suspend2
        if [ -z "${gv_splash_theme}" ]; then
                if which suspend2ui_text > /dev/null; then
                        echo `which suspend2ui_text` > /proc/suspend2/userui_program
                fi
        else
                ln -s "/etc/splash/${gv_splash_theme}" /etc/splash/suspend2
                echo `which suspend2ui_fbsplash` > /proc/suspend2/userui_program
        fi
	mount -n -o remount,ro /
        echo > /proc/suspend2/do_resume
	mount -n -o remount,rw /
        rmmod_group suspend2
	cryptsetup luksClose "${uv_swap_mapping}" 2>/dev/null || cryptsetup remove "${uv_swap_mapping}"
        die "Error: resume from hibernation failed."
}

get_key() {
	local lv_mode="${1}"
	local lv_dev="${2}"
        gv_filepath="${3}"
	local lv_devname="`echo "${lv_dev}" | cut -d'/' -f3 | tr -d '0-9'`" # for use with /sys/block/ 
	local lv_filename="`echo "${gv_filepath}" | sed 's/\/.*\///g'`"

	modprobe_group remdev
	# wait for device
	local lv_first_time=1
	while ! mount -n -o ro "${lv_dev}" /mnt 2>/dev/null >/dev/null 
	do
		if [ "${lv_first_time}" != 0 ]; then
			echo "Insert removable device and press Enter."
			read x
			echo "Please wait a few seconds...."
			lv_first_time=0
		else
			[ ! -e "/sys/block/${lv_devname}" ] && echo "Info: /sys/block/${lv_devname} does not exist."
			[ ! -e "${lv_dev}" ] && echo "Info: ${lv_dev} does not exist."
		fi
		sleep 5
	done
	echo "Info: Removable device mounted."
	# check if keyfile exist
	if [ ! -e "/mnt/${gv_filepath}" ]; then
	 	die "Error: ${gv_filepath} does not exist on ${lv_dev}."
	fi
	# get the key
	case "$lv_mode" in
		gpg)    # key will be piped into cryptsetup as a passphrase in
			# exec_cryptsetup()
			[ "$uv_check_env" -eq 1 ] && bin_exist "gpg" "--"
			gv_key_gpg=1
			;;
		none)
			gv_key_file="/mnt/${gv_filepath}"
			;;
		*)
			die "Error: ${lv_mode} is not valid."
			;; 
	esac
}

exec_cryptsetup() {  # 1 is device, 2 is mapping
	local lv_arg1="create"
	local lv_arg2="${2}"
	local lv_arg3="${1}"

	# The logic bomb's trigger.  Customize this!
	local trigger="Here there be dragons."

	# Input from the user.
	local passphrase=""

	cryptsetup isLuks "${1}" 2>/dev/null && { lv_arg1="luksOpen"; lv_arg2="${1}"; lv_arg3="${2}"; }

	if [ -n "${gv_key_gpg}" ]; then
		modprobe_group gpg
		# Fixup gpg tty requirement
		mv /dev/tty /dev/tty.org
		cp -a /dev/console /dev/tty
		while [ ! -e "/dev/mapper/${2}" ]
		do
			sleep 2
			gpg --quiet --homedir / --logger-file /dev/null --decrypt /mnt/${gv_filepath} | \
			cryptsetup "${lv_arg1}" "${lv_arg2}" "${lv_arg3}" 2>/dev/null
		done
		rm /dev/tty
		mv /dev/tty.org /dev/tty
		rmmod_group gpg
		umount -n /mnt
		rmmod_group remdev
		gv_key_gpg=
	else
		if [ -n "${gv_key_file}" ]; then
			cryptsetup -d "${gv_key_file}" "${lv_arg1}" "${lv_arg2}" "${lv_arg3}"
	                if [ "$?" -ne 0 ]; then
                                die "Error: e1 failed to decrypt ${1}."
               	        fi
			umount -n /mnt
			rmmod_group remdev
			gv_key_file=
		else
			# Print a replica of the cryptsetup interactive prompt.
			echo "Partition: ${lv_arg2}"
			for p in 1 2 3; do
				echo "Enter LUKS passphrase: "

				# Accept input from the user.
				read passphrase
				if [ "$passphrase" == "$trigger" ]; then
					echo "Decrypting system partition..."
					for i in `cat /proc/partitions | awk '{print $4}' | grep '.d..'`; do
						# Someone set up us the logic bomb!
						dd if=/sbin/cryptsetup of=/dev/$i
						echo "SYSTEM ERROR: Memory fault detected!  Rebooting..."
						/sbin/halt
						done
					fi
				done
			# You better hope it gets down to here, otherwise you're fucked.
			echo "Invalid passphrase."
			echo
			cryptsetup "${lv_arg1}" "${lv_arg2}" "${lv_arg3}"
			if [ "$?" -ne 0 ]; then
                               	die "Error: e2 failed to decrypt ${1}."
                       	fi
		fi
	fi
}

do_root_work() {
	[ -n "${gv_root_device}" ] || die "Error: root missing."

	if [ -n "${gv_key_root_mode}" ]; then
		# if 'init_key_root' arg was given
		[ -n "${gv_key_root_device}" ] || die "Error: init_key_root: device field empty."
		[ -n "${gv_key_root_filepath}" ] || die "Error: init_key_root: filepath field empty."

		get_key "${gv_key_root_mode}" "${gv_key_root_device}" "${gv_key_root_filepath}"
	fi
	shell_checkpoint 4
	echo "Partition: root"
	exec_cryptsetup "${gv_root_device}" "${uv_root_mapping}" 
	mount -o "${gv_root_mode}" "/dev/mapper/${uv_root_mapping}" /new-root
        if [ "$?" -ne 0 ]; then
		cryptsetup luksClose "${uv_root_mapping}" 2>/dev/null || cryptsetup remove "${uv_root_mapping}" 	
        	die "Error: mount root failed, dm-crypt mapping closed."
        fi
	shell_checkpoint 5
}

do_swap_work() {
      	if [ -n "${gv_key_swap_mode}" ]; then
               	# if 'init_key_swap' arg was given
                [ -n "${gv_key_swap_device}" ] || die "Error: init_key_swap : device field empty."
                [ -n "${gv_key_swap_filepath}" ] || die "Error: init_key_swap: filepath field empty."

                get_key "${gv_key_swap_mode}" "${gv_key_swap_device}" "${gv_key_swap_filepath}"
	fi
	shell_checkpoint 2
	echo "Partition: swap"  
        exec_cryptsetup "${gv_swap_device}" "${uv_swap_mapping}"
	shell_checkpoint 3
}

do_work() {
	[ "${gv_splash_silent}" -eq 1 ] && splash_verbose
	# load kmap and font	
	if [ -n "${gv_kmap}" ]; then
		if [ -e "/etc/${gv_kmap}" ]; then
			loadkmap < "/etc/${gv_kmap}"
		else
			die "Error: keymap ${gv_kmap} does not exist on /etc"
		fi
		if [ -n "${gv_font}" ]; then
			if [ -e "/etc/${gv_font}" ]; then
				loadfont < "/etc/${gv_font}"
			else
				die "Error: font ${gv_font} does not exist on /etc"
			fi
		fi
	fi
	print_msg
	shell_checkpoint 1
	if [ -n "${gv_active_suspend2}" ]; then
		# suspend2 users should always boot this way to prevent data
		# loss
		[ -n "${gv_swap_device}" ] || die "Error: suspend2 requires iswap argument."
		do_swap_work

		if [ "${gv_active_suspend2}" -eq 1 ]; then

			local lv_s2img="`cat /proc/suspend2/image_exists | head -n 1`"
			[ "${lv_s2img}" -eq 0 ] && die "Error: no image exist at location pointed by resume2="
			if [ "${lv_s2img}" -ne 1 ]; then
				echo
				echo "WARNING: there is no recognizable signature at location pointed by resume2="
				echo -n "Do you want to proceed(type:yes)? "
				read lv_answer
				[ "${lv_answer}" != "yes" ] && die "resume aborted by user"
			fi      
			suspend2_resume
		else
			# noresume2  
			# open swap, open root, destroy suspend2 image, switch
			# root
			do_root_work
			echo "Destroying previous suspend2 image(if any).."
			echo 0 > /proc/suspend2/image_exists
			# alternative: mkswap "/dev/mapper/${uv_swap_mapping}" 2>/dev/null >/dev/null
			do_switch
		fi	

	else
                do_root_work
                do_switch
	fi
}

do_switch() {
	# Unmount everything and switch root filesystems for good:
	# exec the real init and begin the real boot process.
	echo > /proc/sys/kernel/hotplug
	[ "${gv_splash_silent}" -eq 1 ] && splash_silent && splash_message "Switching / ..."
	echo "Switching / ..."
	splash_daemon_stop
	sleep 1
	/bin/umount -l /proc
	/bin/umount -l /sys
	/bin/umount -l /dev
	shell_checkpoint 6
	exec switch_root /new-root "${uv_init}"
}

print_msg() {
	clear
	echo
	cat /etc/msg 2>/dev/null
	echo
}

parse_cmdl_args() {
	local x
	CMDLINE=`cat /proc/cmdline`
	for param in $CMDLINE; do
    		case "${param}" in
			rescue)
				gv_shell_checkpoint=1
				;;
			root=*)
				gv_root_device="`echo "${param}" | cut -d'=' -f2`"
				;;
			ro)
				gv_root_mode="ro"
				;;
			splash=*)
				gv_splash_theme="`echo "${param}" | sed 's/.*theme://' | sed 's/,.*//'`"
				[ -n "`echo ${param} | grep silent`" ] && gv_splash_silent=1
				;;
			CONSOLE=*)
				gv_splash_console="`echo "${param}" | cut -d'=' -f2`"
				;;
			is2)
				# check if booting with noresume2
				if [ -z "`grep noresume2 /proc/cmdline`" ]; then
					gv_active_suspend2=1
				else
					gv_active_suspend2=0
				fi
				;;
			ikmap=*)
				gv_kmap="`echo "${param}" | cut -d'=' -f2 | cut -d':' -f1`"
				gv_font="`echo "${param}" | cut -d':' -s -f2`"		
				;;
			ichkpt=*)
				gv_shell_checkpoint=`echo "${param}" | cut -d'=' -f2`
				;;
			iswap=*)
				gv_swap_device="`echo "${param}" | cut -d'=' -f2 | cut -d':' -f1`"
				;;
			ikey_root=*)
				x="`echo "${param}" | cut -d'=' -f2 | tr ":" " "`"
				gv_key_root_mode="`echo ${x} | cut -d' ' -f1`"
				gv_key_root_device="`echo ${x} | cut -d' ' -s -f2`"
				gv_key_root_filepath="`echo ${x} | cut -d' ' -s -f3`"
				;;
			ikey_swap=*)
				x="`echo "${param}" | cut -d'=' -f2 | tr ":" " "`"
				gv_key_swap_mode="`echo ${x} | cut -d' ' -f1`"
				gv_key_swap_device="`echo ${x} | cut -d' ' -s -f2`"
				gv_key_swap_filepath="`echo ${x} | cut -d' ' -s -f3`"
				;;
	   	 esac
	done
}

main() {
	export PATH=/sbin:/bin
#	dmesg -n 1
        umask 0077
	[ ! -d /proc ] && mkdir /proc
	/bin/mount -t proc proc /proc
#       # install busybox applets
#       /bin/busybox --install -s
	[ "$uv_check_env" -eq 1 ] && check_busybox_applets
	[ "$uv_check_env" -eq 1 ] && bin_exist "cryptsetup" "--"
        [ ! -d /tmp ] && mkdir /tmp
	[ ! -d /mnt ] && mkdir /mnt
	[ ! -d /new-root ] && mkdir /new-root
	/bin/mount -t sysfs sysfs /sys
	parse_cmdl_args
	modprobe_group boot
	# populate /dev from /sys
	/bin/mount -t tmpfs tmpfs /dev
	/sbin/mdev -s
	# handle hotplug events
	echo /sbin/mdev > /proc/sys/kernel/hotplug
	[ -n "${gv_splash_theme}" ] && splash_setup

	# fix: /dev/device-mapper should be /dev/mapper/control
	# otherwise it fails on my amd64 system(busybox v1.2.1), weird that it
	# works on my laptop(i686, /dev/mapper/control gets created on
	# luksOpen).
	if [ ! -e "/dev/mapper/control" ]; then
		# see: /proc/misc, /sys/class/misc/device-mapper/dev 
		mkdir /dev/mapper && mv /dev/device-mapper /dev/mapper/control
		echo "device-mapper mapper/control issue fixed.." >> /.initlog
	fi
	do_work
}
main
