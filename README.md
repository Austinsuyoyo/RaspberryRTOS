# RPI RTOS

Easy setup with buildroot to build rpi os with xenomai patch!

# Usage

1. Select a target to build, target will be {TARGET}_defconfig that config file in buildroot-external/configs

    `make rpi3_64_4.19`

2. Burning image to sdcard
	
    `sudo dd if=./build-rpi3_64_4.19/images/sdcard.img of=/dev/sdx`

3. Insert SD
4. Hack it!

# Support
| Hardware | Arch | Xenomai | Xenomai patch | Linux kernel | raspberry linux commit |
|----------|------|---------|---------------|--------------|--------|
|Raspberry Pi 3 Model B| ARM   | 3.1 | unofficial-ipipe-core-4.19.128-arm-9.patch  | 4.19.127| [bfef951a177d4d3f10e8b5072316a517d68a2a27](https://github.com/raspberrypi/linux/tree/bfef951a177d4d3f10e8b5072316a517d68a2a27) |
|Raspberry Pi 3 Model B| ARM64 | 3.1 | unofficial-ipipe-core-4.19.144-arm64-7.patch | 4.19.127| [bfef951a177d4d3f10e8b5072316a517d68a2a27](https://github.com/raspberrypi/linux/tree/bfef951a177d4d3f10e8b5072316a517d68a2a27) |


# Reference

- [Xenomai Patch](https://xenomai.org/downloads/ipipe/)
- [raspberry linux kernel](https://github.com/raspberrypi/linux)