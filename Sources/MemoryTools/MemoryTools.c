#import <stdio.h>

#ifdef __APPLE__

#import <mach/mach.h>

unsigned long getMemoryUsed() {
    struct task_basic_info info;
    mach_msg_type_number_t size = TASK_BASIC_INFO_COUNT;
    kern_return_t errorCode = task_info (mach_task_self(),
                                         TASK_BASIC_INFO,
                                         (task_info_t)&info,
                                         &size);

    if (errorCode == KERN_SUCCESS) {
        return info.resident_size;
    } else {
        printf ("Failed to retrieve memory used: %d\n", errorCode);
        return -1;
    }
}

#endif

#ifdef __linux__

unsigned long getMemoryUsed() {
    FILE* stat = fopen ("/proc/self/stat", "r");
    long rss = 0;

    if (stat == NULL) {
        return 0;
    } else {
        if (fscanf (stat, "%*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %*s %ld", &rss) < 1) {
            rss = 0;
        }

        fclose (stat);
        return rss;
    }
}

#endif
