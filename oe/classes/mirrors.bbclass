DEBIAN_MIRROR = "http://http.us.debian.org/debian/pool"
GNU_MIRROR = "http://mirrors.kernel.org/gnu"
# KERNELORG_MIRROR = "http://ftp.us.kernel.org"
# KERNELORG_MIRROR = "http://mirrors.arsc.edu/kernel"
KERNELORG_MIRROR = "http://mirror.nexcess.net/kernel.org"


PREMIRRORS = ""
MIRRORS () {
${DEBIAN_MIRROR}	ftp://archive.debian.org/debian/pool
http://www.apache.org/dist  http://archive.apache.org/dist
ftp://.*/.*     http://sources.openembedded.org/
https?$://.*/.* http://sources.openembedded.org/
git://git.kernel.org/pub/ http://mirror.nexcess.net/kernel.org/
}
