# LockWhenGone

A script that automatically locks, shuts down, reboots, or runs a script on your computer when your phone, or other devices, become undetectable. More details in the [Purpose](#purpose) section.

Found this useful? Please consider starring this repo, or donating at the sponsorship links in the sidebar, or by clicking button below. Thank you.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/V7V84X6JM)

# Table of Contents

- [LockWhenGone](#lockwhengone)
- [Table of Contents](#table-of-contents)
  - [Purpose](#purpose)
  - [Installation Guide](#installation-guide)
    - [Requirements](#requirements)
    - [Download the files](#download-the-files)
    - [Edit Device Files](#edit-device-files)
      - [some-required.txt](#some-requiredtxt)
      - [all-required.txt](#all-requiredtxt)
      - [not-allowed.txt](#not-allowedtxt)
    - [Add Your devices](#add-your-devices)
      - [Adding USB Devices](#adding-usb-devices)
      - [Adding Bluetooth Devices](#adding-bluetooth-devices)
      - [Adding ping addresses](#adding-ping-addresses)
      - [Adding website addresses](#adding-website-addresses)
      - [Adding network devices (required root)](#adding-network-devices-required-root)
    - [Run the script](#run-the-script)
  - [CLI Options](#cli-options)
  - [Config](#config)
    - [Exit Action (EXIT\_ACTION)](#exit-action-exit_action)
    - [Exit Script (EXIT\_SCRIPT)](#exit-script-exit_script)
    - [Shutdown Command (SHUTDOWN\_COMMAND)](#shutdown-command-shutdown_command)
    - [Reboot Command (REBOOT\_COMMAND)](#reboot-command-reboot_command)
    - [Lock Command (LOCK\_COMMAND)](#lock-command-lock_command)
    - [Minimum Devices (MIN\_DEVICES)](#minimum-devices-min_devices)
  - [To Do](#to-do)
  - [Changelog](#changelog)

## Purpose

The intended purpose of this script is to check every X seconds whether your phone(s) or other devices are detectable, and if they aren't, then lock, shutdown, reboot, or run a script on the computer automatically. I initially made this so that if I leave home, my computer will lock itself. It checks for devices that are on the local network, connected by Bluetooth, or by USB. It can also ping IPs or load URLs. Devices are split into 3 groups, ones which should never be connected, ones which must always be connected, and a group of devices where at least 1 must always be connected(configurable).

I only use Linux, so this is only currently planned to run on Linux. I will test and add more Linux distributions when I distro hop.

## Installation Guide

### Requirements

By default, this script uses `lsusb` (for USB devices), `bluetoothctl` (for Bluetooth devices), `ping` (for ip addresses), `curl` (for URLs), and `arp-scan` (for the local network). Some or all of these may be installed on your system already. 

Note: `arp-scan` requires root. If you can't or don't want to run the script as root, then the next best option is `ping`.

You can install them with your preferred package manager, for example with Ubuntu:

```
# Remove packages that you don't need
sudo apt install usbutils bluez iputils-ping curl arp-scan
```

Repos:

> usbutils: https://github.com/gregkh/usbutils
>
> bluez: https://github.com/bluez/bluez
>
> iputils-ping: https://github.com/iputils/iputils
>
> curl: https://github.com/curl/curl
>
> arp-scan: https://github.com/royhills/arp-scan

### Download the files

Make a new directory, then download the files to it. The commands below create `lockwhengone` directory in your home directory.

```
mkdir ~/lockwhengone
curl -L http://github.com/pbiswell/lockwhengone/archive/main.tar.gz | tar zxf - -C ~/lockwhengone --strip-components=1
cd ~/lockwhengone
```

### Edit Device Files

You can add devices to the device list files `some-required.txt`, `all-required.txt`, or `not-allowed.txt`, depending on how important the devices are.

How to get your device information is detailed in the [Add Your Devices section](#add-your-devices).

All devices must be on a new line, and start with the device type followed by a colon (eg. usb:XXXX:XXXX). Comment lines (lines starting with #) are ignored.

#### some-required.txt

Add devices to this list when only some must be found, by default 1. (You can change MIN_DEVICES in config.conf)

If the number of found devices is below the minimum required amount, and the list is not empty, the exit action will be triggered.

For example, you have 2 phones but don't always have both with you. Or a device which may sometimes be connected by Bluetooth, or sometimes be connected to the local network.

#### all-required.txt

Only add devices to this list which must always be found. If any device listed in this file is not findable, the exit action will be triggered.

For example, a mobile phone which is always with you, or a USB security key which you always disconnect when you leave.

#### not-allowed.txt

Only add devices to this list which should never be found. If any device listed in this file is findable, the exit action will be triggered.

For example, a designated device that only connects in order to trigger the exit action.

### Add Your devices

You must add your chosen devices to device files listed in the [Edit Device Files section](#edit-device-files).

#### Adding USB Devices

Find your connected USB devices by running command:

```
lsusb
```

Example output:

```
$ lsusb
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 001 Device 003: ID 046d:c514 Logitech, Inc. Cordless Mouse
```

If you decide to add the `046d:c514 Logitech, Inc. Cordless Mouse` from the example output, you can add any of these lines to your [chosen device file](#edit-device-files):

```
usb:046d:c514
# or
usb:046d:c514 Logitech, Inc. Cordless Mouse
# or
usb:Logitech, Inc. Cordless Mouse
```

#### Adding Bluetooth Devices

Connect your Bluetooth device to your computer, then run the command:

```
bluetoothctl devices Connected
```

Example output:

```
$ bluetoothctl devices Connected
Device E7:FC:C6:D5:5E:F6 My Phone
Device CA:EC:2F:67:FE:6D John's cowboy hat
```

If you decide to add the `E7:FC:C6:D5:5E:F6 My Phone` from the example output, you can add any of these lines to your [chosen device file](#edit-device-files):

```
bluetooth:E7:FC:C6:D5:5E:F6
# or
bluetooth:E7:FC:C6:D5:5E:F6 My Phone
# or
bluetooth:My Phone
```

#### Adding ping addresses

You can add IP addresses or domains to ping. Non-local addresses may take a long time to respond.

You could use `ping:google.com` as a sanity check, assuming Google never goes down.

If you want to ping `192.168.1.1`, for example, you would add this line to your [chosen device file](#edit-device-files):

```
ping:192.168.1.1
```

#### Adding website addresses

By default, this checks that a URL returns a `200`, `301`, or `302` HTTP status code, which indicates success or redirection.

You can check a URL with this command:

```
curl -si https://www.google.com | head -n 1
```

Example output:

```
$ curl -si https://www.google.com | head -n 1
HTTP/2 200
```

You can use this to check if a website is up, or webpage exists. You could use this to remotely lock or shutdown your computer, by making a specific webpage unavailable on a website you control. However, this could fail if the computer's internet connection goes down, which may also be what you want.

If you wanted to check, for example, that `https://paulbiswell.co.uk` was returning a 200 HTTP success code, you would add this line to your [chosen device file](#edit-device-files):

```
url:https://paulbiswell.co.uk
```

#### Adding network devices (required root)

Run this command to find your network devices:

```
# Change to your local network
sudo arp-scan 192.168.1.0/24
```

Example output:

```
$ sudo arp-scan 192.168.1.0/24
Starting arp-scan 1.10.0 with 256 hosts (https://github.com/royhills/arp-scan)
192.168.1.1	34:d8:56:6d:bc:4b	(Unknown)
192.168.1.2	7c:a1:ae:54:9c:13	(Unknown)
192.168.1.3	b6:ca:a7:e9:79:6a	(Unknown)
```

If you decide to add `(192.168.1.4) at 8c:5f:df:22:d2:39` from the example output, you can add this line to your [chosen device file](#edit-device-files):

```
network:8c:5f:df:22:d2:39
```

### Run the script

Once you have entered your devices in the device list file(s), you can run the script with this command:

```
./lockwhengone.sh
```

Example output:

```
$ ./lockwhengone.sh
Success: Completed all checks without triggering exit action.
Sleeping for 30 seconds before running again. Press CTRL+C to exit script.
```

**Verbose output:**

```
./lockwhengone.sh -v
```

## CLI Options

**Help**

Displays help information

```
./lockwhengone.sh --help
```

**Version**

Displays the version number

```
./lockwhengone.sh --version
```

**Verbose Output**

Show verbose/detailed output

```
./lockwhengone.sh --verbose
```

**Custom Config**

Use a custom config file

```
./lockwhengone.sh -c [FILE]
# For example:
./lockwhengone.sh -c "~/myconfig.conf"
```

**Disable Coloured Output**

Disable the coloured output

```
./lockwhengone.sh -d
```

## Config

### Exit Action (EXIT_ACTION)

The action that is triggered based on devices found/not found.

Name: `EXIT_ACTION`

Default value: `lock`

Options: `lock` `shutdown` `reboot` `script` `debug`

> **lock**: Locks the computer (Default)
>
> **shutdown**: Shuts down the computer
>
> **reboot**: Reboots the computer
>
> **script**: Runs the script in EXIT_SCRIPT
>
> **debug**: Only outputs a trigger message

### Exit Script (EXIT_SCRIPT)

The script to run when `EXIT_ACTION=script`

Name: `EXIT_SCRIPT`

Default value: (no value)

> Change this to the location of the script file you want to run.

### Shutdown Command (SHUTDOWN_COMMAND)

The command to run when `EXIT_ACTION=shutdown`

Name: `SHUTDOWN_COMMAND`

Default value: `"shutdown -h now"`

> Change this to your favourite shutdown command.

### Reboot Command (REBOOT_COMMAND)

The command to run when `EXIT_ACTION=reboot`

Name: `REBOOT_COMMAND`

Default value: `"reboot"`

> Change this to your favourite reboot command.

### Lock Command (LOCK_COMMAND)

The command to run when `EXIT_ACTION=lock`

Name: `LOCK_COMMAND`

Default value: `"xdg-screensaver lock"`

> Change this to the desktop lock command (may change depending on distro).

### Minimum Devices (MIN_DEVICES)

The mimimum amount of devices to be found in `some-required.txt`

Name: `MIN_DEVICES`

Default value: `1`


## To Do

* Add retries for `ping:` and `url:`
* More detailed documentation
* Add devices from command line

## Changelog

* v0.0.1
  > Initial release
