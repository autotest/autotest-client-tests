struct A
  {
    char a;
    struct A *b;
    int *c;
  };

extern struct A foo;
extern int bar;
extern int f1 (void);
extern int f2 (void);
extern struct A *f3 (void);
