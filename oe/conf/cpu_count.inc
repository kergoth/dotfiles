def in_vmware():
    try:
        return 'vmware' in open('/proc/timer_list', 'r').read()
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
        return get_proc_cpucount()
    else:
        return multiprocessing.cpu_count()

def adjusted_cpu_count(d):
    count = cpu_count()
    if in_vmware():
        factor = float(d.getVar('VMWARE_FACTOR', True) or 1)
    else:
        factor = 1

    return count * factor

def round(num):
    return max(1, int(num + .5))

CPU_VMWARE_FACTOR ?= ".5"
CPU_THREAD_FACTOR ?= "1.5"
CPU_MAKE_FACTOR ?= "2"

BB_NUMBER_THREADS := "${@round(adjusted_cpu_count(d) * float('${CPU_THREAD_FACTOR}'))}"
PARALLEL_MAKE := "-j${@round(adjusted_cpu_count(d) * float('${CPU_MAKE_FACTOR}'))}"
