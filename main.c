#include "lib.h"
#include <iostream>

int main()
{
    lib* Lib;
    Lib = new lib();
    Lib->display();
    delete Lib;

    // lib Lib;
    // Lib.display();

    return 0;
}