# ASSUME_PROVIDED Notes:
#
# Seemingly safe
#bison-native
#bzip2-full-native
#chrpath-native
#fakeroot-native
#git-native
#m4-native
#openssl-native
#sed-native
#unzip-native
#zlib-native

# Unknown
#curl-native
#flex-native
#gettext-native
#glib-2.0-native
#gmp-native
#gperf-native
#guile-native
#ipkg-utils-native
#libxml2-native
#mpfr-native
#opkg-native
#pkgconfig-native
#quilt-native
#readline-native
#unifdef-native
#qemu-native

# Patched
#autoconf-native
#automake-native
#coreutils-native
#libtool-native

# Need specific versions
#file-native - magic file versions have to match up
#ncurses-native - tic version has to match up
#perl-native
#python-native

def auto_assume_provided(d):
    try:
        oe_import(d)
    except NameError:
        pass

    import kergoth.assume as assume
    import kergoth.assumptions

    return ' '.join(assume.test_assumptions())

ASSUME_PROVIDED += "${@auto_assume_provided(d)}"
