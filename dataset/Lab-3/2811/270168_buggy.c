/*numPass=3, numTotal=6
Verdict:ACCEPTED, Visibility:1, Input:"1 0 0 1", ExpOutput:"(1.000,1.000)
", Output:"(1.000,1.000)"
Verdict:ACCEPTED, Visibility:1, Input:"1 0 1 0", ExpOutput:"INF
", Output:"INF"
Verdict:WRONG_ANSWER, Visibility:1, Input:"-1.25 0 5 4", ExpOutput:"(-0.800,1.250)
", Output:"(1.250,-0.800)"
Verdict:WRONG_ANSWER, Visibility:0, Input:"1 -2 -100 201", ExpOutput:"(203.000,101.000)
", Output:"(101.000,203.000)"
Verdict:ACCEPTED, Visibility:0, Input:"-1000 1 2000 -2", ExpOutput:"INF
", Output:"INF"
Verdict:WRONG_ANSWER, Visibility:0, Input:"0 1 0.0000001 1", ExpOutput:"(-0.000,1.000)
", Output:"(1.000,-0.000)"
*/
#include<stdio.h>

int main()
{
    float a1,b1,a2,b2;
    scanf("%f %f %f %f",&a1,&b1,&a2,&b2);
    if((a1*b2-a2*b1)==0)
    printf("INF");
    else
    {
        float a=(a1-a2)/(a1*b2-a2*b1);
        float b=(b2-b1)/(a1*b2-a2*b1);
        printf("(%.3f,%.3f)",a,b);
    }
 
    return 0;
}