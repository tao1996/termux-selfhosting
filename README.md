# Self-hosting Termux app

A v0.99 source bundle of [Termux](https://github.com/termux/termux-app) with
special modifications so you can compile its APK within any running Termux
instance.

Here is a brief list of Termux source tree changes:
* Removed lambdas.
* Merged dependencies (AndroidX).

## How to

In order to build APK, you need only `aapt`, `apksigner`, `clang`, `dx` and
`ecj`. No Android SDK, OpenJDK or Linux distribution chroot required.

Just execute the script `./make-termux.sh` located at the root of Git
repository and it will do all steps automatically. When it finishes, you
will get a `termux-signed.apk` file which can be installed with file manager.

Note that application is built for current device architecture. So if you
built APK on AArch64 device, it will not work on ARM.
