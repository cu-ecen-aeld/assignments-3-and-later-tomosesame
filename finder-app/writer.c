#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>
#include <string.h>
#include <errno.h>

int main(int argc, char *argv[]) {
    openlog("writer", LOG_PERROR | LOG_PID, LOG_USER);

    if (argc != 3) {
        syslog(LOG_ERR, "Usage: %s <file_path> <string>", argv[0]);
        exit(EXIT_FAILURE);
    }

    const char *file_path = argv[1];
    const char *string = argv[2];

    FILE *file = fopen(file_path, "w");
    if (!file) {
        syslog(LOG_ERR, "Failed to open file %s: %s", file_path, strerror(errno));
        exit(EXIT_FAILURE);
    }

    fprintf(file, "%s", string);
    syslog(LOG_DEBUG, "Writing %s to %s", string, file_path);

    if (fclose(file) != 0) {
        syslog(LOG_ERR, "Failed to close file %s: %s", file_path, strerror(errno));
        exit(EXIT_FAILURE);
    }

    closelog();
    return EXIT_SUCCESS;
}
