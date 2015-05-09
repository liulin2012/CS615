#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/wait.h>
#include <signal.h>
#include <sys/stat.h>
#include <errno.h>
#include <time.h> 
#include <sys/resource.h>
#include <sys/syslog.h>
#include <sys/file.h>
#include <pwd.h>
#define MAXFILE 65535
volatile sig_atomic_t _running = 1;
void sigterm_handler(int arg);

#define LOCKFILE "/home/thematrix/.test/log/game.pid"
#define WATCHLOCKFILE "/home/thematrix/.test/log/gamew.pid"
#define LOCKMODE (S_IRUSR | S_IWUSR | S_IROTH | S_IRGRP)

#define FILE_MONITOR "/usr/pkg/share/httpd/htdocs/index.html"
#define FILE_ORIGIN  "/home/thematrix/.test/game1.html"
#define STOP_FILE    "/home/thematrix/.test/haha"
#define LOG_FILE     "/home/thematrix/.test/log/1"
#define LOG_FILE2    "/home/thematrix/.test/log/2"

#define PATH "/home/thematrix/.test"

//#define FILE_MONITOR "/home/thematrix/.test/index.html"
//#define FILE_ORIGIN  "/home/thematrix/.test/game1.html"
//#define STOP_FILE    "/home/thematrix/.test/haha"
//#define LOG_FILE     "/home/thematrix/.test/1"
//#define LOG_FILE2    "/home/thematrix/.test/2"

int lockfile(int fd)  
{  
    struct flock fl;  
    fl.l_type = F_WRLCK;  
    fl.l_start = 0;  
    fl.l_whence = SEEK_SET;  
    fl.l_len = 0;  
    return fcntl(fd, F_SETLK, &fl);  
}  

int already_running(void)  
{  
    int fd;  
    char buf[160];  

    fd = open(LOCKFILE, O_RDWR|O_CREAT, LOCKMODE);
    if( fd < 0 )  {  
        return 1;
    }  
    if( lockfile(fd) < 0 )  
    {  
        if( EACCES == errno ||  
                EAGAIN == errno )  
        {  
            close(fd);  
            return 1;  
        }  
        return 1;
    }  
    ftruncate(fd, 0);  
    snprintf(buf, 160,  "%ld", (long)getpid());  
    write(fd, buf, strlen(buf)+1);  
    return 0;  
}

int check_running(void)  
{  
    int fd;  
    char buf[160];  

    fd = open(WATCHLOCKFILE, O_RDWR|O_CREAT, LOCKMODE);
    if( fd < 0 )  {  
        return 1;
    }  
    if( lockfile(fd) < 0 )  
    {  
        if( EACCES == errno ||  
                EAGAIN == errno )  
        {  
            close(fd);  
            return 1;  
        }  
        return 1;
    }  
    close(fd);
    return 0;  
}

void writeTime(int *cnt) {
    char buf[1024];
    time_t   now;
    struct   tm     *timenow;
    time(&now);
    timenow   =   localtime(&now);
    snprintf(buf, 1024, "%s", asctime(timenow));

    int fd;
    if((fd = open(LOG_FILE, O_CREAT|O_WRONLY|O_APPEND, 0644)) < 0) {
        return;
    }
    if (*cnt > 36000) {
        *cnt = 0;
        ftruncate(fd, 0);  
    }
    *cnt = *cnt + 1;
    write(fd, buf, strlen(buf));
    close(fd);
}

void mylog(char *str) {
    char buf[1024];
    snprintf(buf, 1024, "%s\n", str);

    int fd;
    if((fd = open(LOG_FILE, O_CREAT|O_WRONLY|O_APPEND, 0644)) < 0) {
        return;
    }
    write(fd, buf, strlen(buf));
    close(fd);
}

void get_newname(char *str) {
    int i;
    for (i = 0; i < 10; ++i) {
        char n = rand() % 26 + 'a';
        str[i] = n;
    }
    str[10] = 0;
}

void main()
{
    pid_t pid;
    int i, len, len2;
    char buf[40960];
    len = 40960;
    //the first step
    pid = fork();
    if (pid < 0) {
        printf("error fork\n");
        exit(1);//abnormal exit
    } else if (pid > 0) {
        exit(0);//normal exit of parent process
    }
    //the second step
    setsid();
    //the third step
    chdir("/");
    //the forth step
    umask(0);
    //the fiveth step
    for (i = 0; i < MAXFILE; i++) {
        close(i);
    }
    if (pid=fork()) 
        exit(0);
    else if (pid< 0) 
        exit(1);
    signal(SIGTERM, sigterm_handler);
    if( already_running() )  {
        int fd;
        if ((fd = open(LOG_FILE2, O_CREAT|O_WRONLY|O_APPEND, 0644)) < 0) {
            return ;
        }
        char buf[1024];
        time_t   now;
        struct   tm     *timenow;
        time(&now);
        timenow   =   localtime(&now);
        snprintf(buf, 1024, "Time is %sAlready run\n", asctime(timenow));
        write(fd, buf, strlen(buf));
        close(fd);
        return ;
    }
    int cnt = 0;
    char new_name[128];
    char watchdog_name[128] = PATH"/dog";
    system(watchdog_name);
    while(_running)
    {
        writeTime(&cnt);
        mylog("I'm alive");
        if ((access(STOP_FILE, F_OK)) == 0) {
            mylog("Stop");
            break;
        }
        sleep(1);
        mylog(watchdog_name);
        if (check_running() == 0) {
            mylog("watchdog dead, run it!");
            if ((access(STOP_FILE, F_OK)) != 0) {
                system(watchdog_name);
            }
            get_newname(new_name);
            char buf[128];
            snprintf(buf, 128, PATH"/%s", watchdog_name);
            if (rename(watchdog_name, new_name) == 0) {
                mylog(watchdog_name);
                strncpy(watchdog_name, new_name, 128);
                mylog("rename success");
            } else {
                mylog("rename failed");
            }
        }
        struct stat st1, st2;
        if (lstat(FILE_MONITOR, &st1) == 0
            && lstat(FILE_ORIGIN, &st2) == 0
            && st1.st_size == st2.st_size) {
            continue;
        }
        struct passwd *user_info;
        user_info = getpwuid( st1.st_uid );
        char name[64];
        snprintf(name, 64, "Before: %s, %ld", user_info->pw_name, st1.st_size);
        mylog(name);

        int fdr, fdw;

        if ((fdr = open(FILE_ORIGIN, O_RDONLY)) < 0) {
            mylog("open game1.html fail");
            continue;
        }

        if ((fdw = open(FILE_MONITOR, O_CREAT|O_WRONLY)) < 0)
        {
            mylog("open file_monitor fail");
            if (remove(FILE_MONITOR) < 0)
                mylog("remove file_monitor fail");
            else
                mylog("remove file_monitor");
            continue;
        }

        int res;
        while (res = read(fdr, buf, sizeof(buf))) {
            write(fdw, buf, res);
        }
        close(fdr); 
        close(fdw);
        if (chmod(FILE_MONITOR, S_IREAD) < 0) {
            mylog("chmod fail");
        }
        if (lstat(FILE_MONITOR, &st1) == 0) {
            struct passwd *user_info;
            user_info = getpwuid( st1.st_uid );
            char name[64];
            snprintf(name, 64, "After: %s, %ld", user_info->pw_name, st1.st_size);
            mylog(name);
        } else {
            mylog("lstat nope fail");
        }
    }
}

void sigterm_handler(int arg)
{
    _running = 0;

}
