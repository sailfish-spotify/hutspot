#include "systemutil.h"
#include <signal.h>

SystemUtil::SystemUtil(QObject *parent) {

}

void SystemUtil::pkill(uint pid, int signal) {
    kill(pid, signal);
}
