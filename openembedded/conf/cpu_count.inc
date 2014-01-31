def in_vmware():
    try:
        return 'vmci' in open('/proc/misc', 'r').read()
    except (OSError, IOError):
        return False

def get_proc_cpucount():
    try:
        cpuinfo = open('/proc/cpuinfo', 'r')
    except (OSError, IOError):
        bb.warn("Unable to determine cpu count, defaulting to 1")
        return 1

    with cpuinfo:
        return len([line for line in cpuinfo if line.startswith('processor')])

def cpu_count():
    try:
        import multiprocessing
    except ImportError:
        # FIXME: run sysctl -n hw.ncpu on Darwin
        return get_proc_cpucount()
    else:
        return multiprocessing.cpu_count()

def mem_factor(d):
    import re
    mem_info = open('/proc/meminfo', 'r').read()
    mem_total = int(re.match('^MemTotal: *([0-9]+)', mem_info).group(1))
    mem_gigs = round(float(mem_total) / (1024 * 1024))
    return mem_gigs * 2

def bb_number_threads(d):
    import math
    scaled_count = math.ceil(cpu_count() * 1.5)
    mem = mem_factor(d)
    if in_vmware():
        vmware_factor = 0.75
    else:
        vmware_factor = 1
    return int(min(scaled_count, mem) * vmware_factor)

def make_jobs(d):
    return int(int(d.getVar('BB_NUMBER_THREADS', True)) * 1.5)

BB_NUMBER_THREADS := "${@bb_number_threads(d)}"
PARALLEL_MAKE := "-j${@make_jobs(d)}"
