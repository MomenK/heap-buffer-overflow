#ifndef LIB_H
#define LIB_H

class lib
{
public:
    /* data */
    int x;
#ifdef COND
    int y;
#endif

public:
    lib(/* args */);
    ~lib();
    void display();
};

#endif
