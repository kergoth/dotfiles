python do_hang () {
    open(bb.data.expand("${TOPDIR}/hang", d), "r").read(1)
}
do_hang[nostamp] = "1"
addtask hang
