PREMIRRORS = "\
(cvs|svn|git|hg|bzr|osc|p4|svk)://.*/.* http://autobuilder.yoctoproject.org/sources/ \n\
(cvs|svn|git|hg|bzr|osc|p4|svk)://.*/.* http://sources.openembedded.org/ \n\
(cvs|svn|git|hg|bzr|osc|p4|svk)://.*/.* http://www.angstrom-distribution.org/unstable/sources/ \n\
"

MIRRORS += "\
${DEBIAN_MIRROR}/main http://snapshot.debian.net/archive/pool \n\
${DEBIAN_MIRROR} ftp://archive.debian.org/debian/pool \n\
http://www.apache.org/dist http://archive.apache.org/dist \n\
(ftp|https?)://.*/.* http://autobuilder.yoctoproject.org/sources/ \n\
(ftp|https?)://.*/.* http://sources.openembedded.org/ \n\
(ftp|https?)://.*/.* http://www.angstrom-distribution.org/unstable/sources/ \n\
${KERNELORG_MIRROR} http://mirror.nexcess.net/kernel.org \n\
git://git.kernel.org/pub/ http://mirror.nexcess.net/kernel.org/ \n\
"
