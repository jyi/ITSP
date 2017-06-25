extern  __attribute__((__nothrow__)) void *memset(void *__s , int __c ,
                                                  unsigned long __n )  __attribute__((__nonnull__(1),
__leaf__)) ;
struct _IO_FILE;
extern int fprintf(struct _IO_FILE * __restrict  __stream ,
                   char const   * __restrict  __format  , ...) ;
extern struct _IO_FILE *fopen(char const   * __restrict  __filename ,
                              char const   * __restrict  __modes ) ;
extern int fflush(struct _IO_FILE *__stream ) ;
extern int fclose(struct _IO_FILE *__stream ) ;
struct _IO_FILE *_coverage_fout  ;
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
  {
  if (_coverage_fout == 0) {
    {
    _coverage_fout = fopen("/home/ubuntu/IntTut/genprog-source-v3.0/test/gcd-test/./coverage.path",
                           "wb");
    }
  }
  }
  {
  fprintf(_coverage_fout, "8\n");
  fflush(_coverage_fout);
  }
  tmp = atoi(*(argv + 1));
  {
  fprintf(_coverage_fout, "9\n");
  fflush(_coverage_fout);
  }
  a = (double )tmp;
  {
  fprintf(_coverage_fout, "10\n");
  fflush(_coverage_fout);
  }
  tmp___0 = atoi(*(argv + 2));
  {
  fprintf(_coverage_fout, "11\n");
  fflush(_coverage_fout);
  }
  b = (double )tmp___0;
  {
  fprintf(_coverage_fout, "12\n");
  fflush(_coverage_fout);
  }
  if (a == (double )0) {
    {
    fprintf(_coverage_fout, "1\n");
    fflush(_coverage_fout);
    }
    printf("%g\n", b);
  } else {
    {
    fprintf(_coverage_fout, "2\n");
    fflush(_coverage_fout);
    }

  }
  {
  fprintf(_coverage_fout, "13\n");
  fflush(_coverage_fout);
  }
  while (1) {
    {
    fprintf(_coverage_fout, "6\n");
    fflush(_coverage_fout);
    }
    if (b != (double )0) {
      {
      fprintf(_coverage_fout, "3\n");
      fflush(_coverage_fout);
      }

    } else {
      break;
    }
    {
    fprintf(_coverage_fout, "7\n");
    fflush(_coverage_fout);
    }
    if (a > b) {
      {
      fprintf(_coverage_fout, "4\n");
      fflush(_coverage_fout);
      }
      a -= b;
    } else {
      {
      fprintf(_coverage_fout, "5\n");
      fflush(_coverage_fout);
      }
      b -= a;
    }
  }
  {
  fprintf(_coverage_fout, "14\n");
  fflush(_coverage_fout);
  }
  printf("%g\n", a);
  {
  fprintf(_coverage_fout, "15\n");
  fflush(_coverage_fout);
  }
  return (0);
}
}
