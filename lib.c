#include <iostream>
#include "lib.h"

lib::lib(/* args */)
{
    x = 0;
#ifdef COND
    y = 0xFFFFFFFF;
#endif

}

lib::~lib()
{
}

void lib::display()
{
#ifdef COND
    std::cout << "value of y is "  << y << std::endl;
#endif
    std::cout << "value of x is "  << x << std::endl;

}