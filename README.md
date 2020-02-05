# tuxbuild-wrappers
A project that wraps tuxbuild to build kernel and rebuild them locally if needed.

### Dependencies
 - bison
 - flex
 - bc
 - pkg-config
 - gcc-aarch64-linux-gnu
 - gcc-arm-linux-gnueabihf
 - gcc-x86-64-linux-gnu
 - jq

### Setup symlinks
```
$ ./install.sh
```

Setup the artifact dir. if not creating an .ragnar.rc file
the artifact dir will be in ${HOME}/tb-artifacts
```
$ echo 'TOP="${HOME}/tb-artifact"' > ${HOME}/.ragnar.rc
```


### pre-req clone linux kernel.
example:
```
$ mkdir kernel/
$ git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
$ cd linux
$ git remote add next https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
$ git remote add stable https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
$ git remote add stable-rc https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable-rc.git
$ git remote update
$ cd ..
```

### Building with build-kernel
example:

```
$ run-tuxbuild.sh -b next-20191219 -r -f ./path/to/a/file/randconfig.yaml
$ run-tuxbuild.sh -b next-20191219 -f ./path/to/a/file/config.yaml
```

### Rebuild locally
example:

```
$ cd <path/to/your/kernel/repostory>
$ git checkout -b next-20191219
$ recreate-local-kernel-tuxbuild.sh
```
