/* zarishell-nvml [PCI_BUS_ID]
 *
 * Prints "busy%\ttempC\tvramUsedB\tvramTotalB\tname" for one NVIDIA GPU
 * (by PCI bus id, e.g. 0000:01:00.0; default: the first GPU) using NVML.
 * libnvidia-ml is loaded at runtime with dlopen, so this builds without the
 * driver and simply prints nothing (exit 1) when NVML is unavailable.
 * Used by shell/scripts/gpustat.sh instead of nvidia-smi, which is slower
 * and has been broken by driver/glibc mismatches.
 */
#include <dlfcn.h>
#include <stdio.h>

typedef void *nvmlDevice_t;
typedef struct { unsigned int gpu, memory; } nvmlUtilization_t;
typedef struct { unsigned long long total, free, used; } nvmlMemory_t;

typedef int (*init_fn)(void);
typedef int (*by_bus_fn)(const char *, nvmlDevice_t *);
typedef int (*by_index_fn)(unsigned int, nvmlDevice_t *);
typedef int (*util_fn)(nvmlDevice_t, nvmlUtilization_t *);
typedef int (*temp_fn)(nvmlDevice_t, int, unsigned int *);
typedef int (*mem_fn)(nvmlDevice_t, nvmlMemory_t *);
typedef int (*name_fn)(nvmlDevice_t, char *, unsigned int);

static const char *libs[] = {
    "libnvidia-ml.so.1",
    "/run/opengl-driver/lib/libnvidia-ml.so.1", /* NixOS driver path */
};

int main(int argc, char **argv)
{
    void *lib = NULL;
    for (unsigned i = 0; !lib && i < sizeof libs / sizeof *libs; i++)
        lib = dlopen(libs[i], RTLD_NOW | RTLD_LOCAL);
    if (!lib)
        return 1;

    init_fn init = (init_fn)dlsym(lib, "nvmlInit_v2");
    init_fn shutdown = (init_fn)dlsym(lib, "nvmlShutdown");
    by_bus_fn by_bus = (by_bus_fn)dlsym(lib, "nvmlDeviceGetHandleByPciBusId_v2");
    by_index_fn by_index = (by_index_fn)dlsym(lib, "nvmlDeviceGetHandleByIndex_v2");
    util_fn util = (util_fn)dlsym(lib, "nvmlDeviceGetUtilizationRates");
    temp_fn temp = (temp_fn)dlsym(lib, "nvmlDeviceGetTemperature");
    mem_fn mem = (mem_fn)dlsym(lib, "nvmlDeviceGetMemoryInfo");
    name_fn name = (name_fn)dlsym(lib, "nvmlDeviceGetName");
    if (!init || !by_bus || !by_index || init() != 0)
        return 1;

    nvmlDevice_t dev = NULL;
    int rc = argc > 1 ? by_bus(argv[1], &dev) : by_index(0, &dev);
    if (rc != 0) {
        if (shutdown)
            shutdown();
        return 1;
    }

    nvmlUtilization_t u;
    unsigned int t;
    nvmlMemory_t m;
    char n[96] = "";
    long long busy = util && util(dev, &u) == 0 ? (long long)u.gpu : -1;
    long long tc = temp && temp(dev, 0 /* NVML_TEMPERATURE_GPU */, &t) == 0 ? (long long)t : -1;
    long long used = -1, total = -1;
    if (mem && mem(dev, &m) == 0) {
        used = (long long)m.used;
        total = (long long)m.total;
    }
    if (!name || name(dev, n, sizeof n) != 0)
        n[0] = '\0';

    printf("%lld\t%lld\t%lld\t%lld\t%s\n", busy, tc, used, total, n);
    if (shutdown)
        shutdown();
    return 0;
}
