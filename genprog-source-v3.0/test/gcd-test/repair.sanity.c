extern int ( /* missing proto */  atoi)() ;
extern int ( /* missing proto */  printf)() ;
int main(int argc , char **argv ) 
{ double a ;
  double b ;
  double c ;
  double r1 ;
  double r2 ;
  int tmp ;
  int tmp___0 ;

  {
  tmp = atoi(*(argv + 1));
  a = (double )tmp;
  tmp___0 = atoi(*(argv + 2));
  b = (double )tmp___0;
  if (a == (double )0) {
    printf("%g\n", b);
  } else {

  }
  while (b != (double )0) {
    if (a > b) {
      a -= b;
    } else {
      b -= a;
    }
  }
  printf("%g\n", a);
  return (0);
}
}
