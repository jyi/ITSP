# An Early Prototype of An Intelligent Tutoring System for Programming #

## URL: [https://github.com/jyi/ITSP](https://github.com/jyi/ITSP) ##

## Contributors ##
   * Jooyong Yi (j.yi@innopolis.ru), Innopolis University
   * Umair Z. Ahmed (umair@cse.iitk.ac.in), Indian Institute of Technology Kanpur
   * Amey Karkare (karkare@cse.iitk.ac.in), Indian Institute of Technology Kanpur
   * Shin Hwei Tan (shinhwei@comp.nus.edu.sg), National University of Singapore
   * Abhik Roychoudhury (abhik@comp.nus.edu.sg), National University of Singapore

## What This Is About ##
In our [ESEC/FSE-17 paper](http://jooyongyi.com/papers/Yi-ESEC-FSE17.pdf) titled **A Feasibility Study of Using Automated Program Repair for Introductory Programming Assignments**, we apply four state-of-the-art automated program repair (APR) tools to student programs collected from an Introductory C Programming course (CS-101) offered in Indian Institute of Technology Kanpur *(IIT-K)*. To overcome the low repair rate of APR tools (due to that student programs are often severely incorrect), we introduce a new repair policy and strategy tailored to programming tutoring (described in Section 6 of our paper), which is implemented in our toolchain. In this repository, we share the artifacts we used in our study. Our artifacts consist of (1) [dataset containing student programs](https://github.com/jyi/ITSP#dataset-student-programs), (2) [toolchain](https://github.com/jyi/ITSP#toolchain), and (3) [user study materials](https://github.com/jyi/ITSP#user-study-materials) (we conducted a user study with students and teaching assistants to see the feasibility of using APR tools). 

**Note**: If you use any part of our tool or data present in this repository, then please do cite our ESEC/FSE-17 paper. 

## Getting Started (via Docker) ##

Our toolchain internally uses four APR tools (GenProg, AE, Angelix, and Prophet) in a synergistic manner. We modified GenProg, AE and Prophet to support our new repair policy and strategy. The modified source code of GenProg/AE and Prophet is available in genprog-source-v3.0 and prophet-gpl, respectively. Note that GenProg and AE share the same codebase. 

These modified APR tools can be installed in the same way as the original tools. It takes long to install APR tools (in particular, Angelix), and we provide a docker container image separately, which can be obtained as follows:

    docker pull jayyi/itsp:0.0

**N.B.** The size of the image is quite large (> 30 GB), due to the huge size of the APR tools.

**N.B.** A more lightweight Docker image, **jayyi/itsp-no-angelix:0.0**, is also available. As the name indicates, this image does not contain Angelix, one of APR tools ITSP can support, and hence the ITSP scripts in this image does not use Angelix. The size of this lightweight image is about 3 GB.

The downloaded docker image can be launched in the standard way:

    docker run -i -t jayyi/itsp:0.0
    
Once a docker container is run, the shell scripts for the toolchain can be found in /ITSP/experiment.
    
    > cd /ITSP/experiment
    > ls *.sh
    base.sh  inc-repair.sh

The base.sh script runs the APR tools using the original repair policy and strategy, whereas inc-repair (standing for "incremental repair") uses our new repair policy and strategy. Both scripts run over 661 student programs available in the [dataset](https://github.com/jyi/ITSP/tree/master/dataset) directory. No parameter is required for both scripts.

    # To run base.sh
    > ./base.sh
    
    # To run inc-repair.sh
    > ./inc-repair.sh

Running the scripts for an individual student program is also possible by assigning the ID of the target program. Both scripts contain the following variables:
    
    export target_lab_id=""
    export target_prob_id=""
    export target_prog_id=""

To run the student program located in [dataset/Lab-10/3239/303888_buggy.c](https://github.com/jyi/ITSP/blob/master/dataset/Lab-10/3239/303888_buggy.c) (see [Dataset (Student Programs)](https://github.com/jyi/ITSP#dataset-student-programs) for a detailed description of the dataset), the variables should be assigned proper values as follows:

    export target_lab_id="Lab-10"
    export target_prob_id="3239"
    export target_prog_id="303888_buggy"

Several example scripts to run an individual target program are available in [/ITSP/experiment/examples/base](https://github.com/jyi/ITSP/tree/master/experiment/examples/base) and [/ITSP/experiment/examples/inc-repair](https://github.com/jyi/ITSP/tree/master/experiment/examples/inc-repair).

    # Examples for base
    > cd /ITSP/experiment/examples/base && ls base*.sh
    base-Lab-10-3241-303507.sh  base-Lab-12-3355-307064.sh  base-Lab-4-2830-271532.sh  
    base-Lab-5-2864-277609.sh  base-Lab-5-2867-277945.sh  base-Lab-9-3106-300235.sh
    
    # Examples for inc-repair
    > cd /ITSP/experiment/examples/inc-repair && ls inc*.sh
    inc-repair-Lab-10-3239-303888.sh  inc-repair-Lab-3-2811-270142.sh  inc-repair-Lab-5-2866-277796.sh  
    inc-repair-Lab-6-2934-280188.sh  inc-repair-Lab-11-3291-305278.sh  inc-repair-Lab-4-2828-271463.sh  
    inc-repair-Lab-5-2870-278288.sh  inc-repair-Lab-7-3075-295455.sh

To run all available examples, type the following:

    # To run all base examples
    > cd /ITSP/experiment/examples/base && ./run.example.sh
    
    # To run all inc-repair examples
    > cd /ITSP/experiment/examples/inc-repair/ && ./run.example.sh

Regarding how to read generated output, see [Toolchain](https://github.com/jyi/ITSP#toolchain).

***

## Local Installation ##

The size of the Docker image is quite large (> 30 GB), which may cause difficulty in downloading and installing the image. This large size is due to that our toolchain, ITSP, is built on top of multiple APR tools whose sizes dominate the size of our Docker image. Nonetheless, we distribute a Docker image, hoping that the image can facilitate other scientific experiments involving state-of-the-art APR tools. However, in case the reader is more interested in quickly trying ITSP without using all the APR tools supported by ITSP, local installation described in this section can be an alternative option.

ITSP is implemented as bash scripts, and hence readily applicable, provided its [prerequisites](#other-prerequisites) are installed. ITSP currently can invoke the following four APR tools: GenProg, AE, Prophet, and Angelix, provided that they are installed. Meanwhile, APR tools that are not installed will be ignored by ITSP.

### Installing Modified GenProg/AE ###

GenProg and AE share the same codebase. ITSP uses GenProg/AE we modified to support our new repair policy and strategy. The source code of the modified GenProg/AE is available in [genprog-source-v3.0](genprog-source-v3.0). The modified GenProg/AE can be installed in the same way as the original GenProg/AE. The official installation instruction is available in [genprog-source-v3.0/README.txt](genprog-source-v3.0/README.txt).

Basically, GenProg/AE can be installed in the following two steps.

1. Installing OCaml
   
2. Building GenProg/AE

```
> cd genprog-source-v3.0
> tar zxvf cil-1.3.7.tar.gz
> cd cil-1.3.7
> ./configure && make && make cillib
> cd ../src
> make
```    

### Installing Modified Prophet ###

We also modified Prophet to support our new repair policy and strategy. The source code of the modified Prophet is available in [prophet-gpl](prophet-gpl). The modified Prophet can be installed in the same way as the original Prophet. The official installation instruction is available in [prophet-gpl/DEPS](prophet-gpl/DEPS).

Basically, Prophet can be installed in the following two steps.

1. Installing Clang and LLVM (version >= 3.5.0)

2. Building Prophet

```
> cd prophet-gpl
> aclocal && autoconf && autoreconf --install && automake
> ./configure
> make clean && make
```

### Installing Angelix ###

ITSP uses the original Angelix, since Angelix already has functionalities our new repair policy and strategy need. Users who want to install Angelix are referred to the official installation instruction of Angelix available in README.md of [https://github.com/mechtaev/angelix](https://github.com/mechtaev/angelix).

### Other Prerequisites ###

Our ITSP bash scripts use the following two external programs.

1. parallel


```
# To install prallel
> wget https://ftp.gnu.org/gnu/parallel/parallel-20161122.tar.bz2
> bzip2 -dc parallel-20161122.tar.bz2 | tar xvf -
> cd parallel-20161122
> ./configure && make && make install
```

2. indent

```
# To install indent
apt-get -y install indent
```

***

## Dataset (Student Programs) ##

Our dataset consists of 661 student programs collected from an Introductory C Programming course (CS-101) offered in Indian Institute of Technology Kanpur *(IIT-K)* for the fall semester-1 15-16. *Section-3* of [ESEC/FSE-17 paper](http://jooyongyi.com/papers/Yi-ESEC-FSE17.pdf) explains how these (buggy-problem, correct-problem) pairs are collected.

These programs were recorded using a web-based IDE - **Prutor: A System for Tutoring CS1 and Collecting Student Programs for Analysis**  (https://arxiv.org/abs/1608.03828)

This dataset is available in the directory of the same name (*dataset*). It contains 
1. Directories for labs 3-12 which in turn contain directories for each unique *problem-ID*. 
    - A total of 661 student programs are spread across these folders (refer to *Table-1* of our [ESEC/FSE-17 paper](ITSP-FSE17.pdf) paper).
    - And each *problem-ID* directory contains a *Main.c* file having the problem statement at the top inside /* comments */ and the code written by instructor.
2. Test directory, which contains the input and corresponding expected output of test-cases, for each *problem-ID*.

**Example:** Consider *problem-ID* 2810 to "calculate the area of triangle"
1. *dataset/Lab-3/2810/* folder contains 
    - *Main.c* : Containing the complete problem statement at top, followed by instructor code below.
    - *270010_buggy.c* : A student code failing on one or more test-cases, identified by *assignment-ID* 270010. The result of running test-cases are provided on top as comments for readability. 
    - *270010_correct.c* : A later code save by the same student, which passes all the test-cases
2. *dataset/test/* folder contains
    - 4 input files: in.2810.1.txt, in.2810.2.txt, in.2810.3.txt and in.2810.4.txt, containing inputs of 4 test-cases for *problem-ID* 2810
    - 4 output files: out.2810.1.txt, out.2810.2.txt, out.2810.3.txt and out.2810.4.txt, containing expected output of 4 test-cases for *problem-ID* 2810 (corresponding to the respective input files)

***

## Toolchain ##

We provide two kinds of toolchain available in the [experiment](https://github.com/jyi/ITSP/tree/master/experiment) directory:

  1. base.sh: this script runs the APR tools using the original repair policy and strategy
  2. inc-repair.sh: this script uses our new repair policy and strategy tailored to programming tutoring

### How to read the output of base.sh ###

The base.sh script (and its example scripts available in [experiment/examples/base](https://github.com/jyi/ITSP/tree/master/experiment/examples/base)) produces output in the result-base file in the current directory (the directory where the script is run), as shown in the following example. 

    > cat result-base
    lab	prob	prog	inst	pos	neg	ww_rep	ga_rep	ag_rep	pr_rep	rep_ok	time
    Lab-12	3355	307064	0	6	3			0		0	18
    Lab-12	3355	307064	1	9	0			0		0	18

The target program, [Lab-12/3355/307064_buggy.c](https://github.com/jyi/ITSP/blob/master/dataset/Lab-12/3355/307064_buggy.c), passes 6 tests (shown in the pos column) and fails 3 tests (neg column). A repair for this program is generated from Angelix (ag_rep column) in 18 seconds (time column). The next row (the last row in this example) shows that the number of failing test is 0 (see the neg column), indicating that the generated repair indeed passes all available tests.

The following is the description of each column:

   * **lab**: lab ID
   * **prob**: problem ID
   * **prog**: program ID
   * **inst**: instance number of tool invocation, starting from 0. In the case of base.sh, this number is always 0 (when the target program is tried to be repaired) or 1 (when checking whether a generated repair actually passes all available tests).
   * **pos**: the number of positive (passing) tests
   * **neg**: the number of negative (failing) tests
   * **ww_rep**: 0 when AE succeeds to generate a repair; 1 when AE fails to generate a repair
   * **ga_rep**: 0 when GenProg succeeds to generate a repair; 1 when GenProg fails to generate a repair
   * **ag_rep**: 0 when Angelix succeeds to generate a repair; 1 when Angelix fails to generate a repair
   * **pr_rep**: 0 when Prophet succeeds to generate a repair; 1 when Prophet fails to generate a repair
   * **rep_ok**: 0 when a repair is found; 1 when a repair is not found
   * **time**: overall time (seconds) taken to generate a repair
   
N.B. XX_rep remains blank when the other repair tool generates a repair, and hence the repair process of XX is stopped. In the prior example, Angelix generates a repair before the other APR tools finish the repair process. 

### How to read the output of inc-repair.sh ###

The inc-repair.sh script (and its example scripts available in [experiment/examples/inc-repair](https://github.com/jyi/ITSP/tree/master/experiment/examples/inc-repair)) produces output in the result-inc-repair file in the current directory (the directory where the script is run), as shown in the following example. 

    > cat result-inc-repair
    lab	prob	prog	inst	pos	neg	ww	ga	pr_df	ag_df	ag_cf	pr_cf	ag_ref	pr_ref	rep_ok	time
    Lab-4	2828	271463	0	4	3					0	1			0	22
    Lab-4	2828	271463	1	5	2					0	1			0	23
    Lab-4	2828	271463	2	6	1			0			1	1	0	0	18
    Lab-4	2828	271463	3	7	0			0			1	1	0	0	

Unlike base.sh, inc-repair.sh supports incremental repair --- in each repair step, the number of passing tests gradually increases. The goal of inc-repair.sh is to generate hints, which are not necessarily complete repairs. In the running example, there are initially 4 passing tests (pos column of the first row) and 3 failing tests (neg column of the first row). After the first repair session, the number of passing tests increase to 5 (4 previously passing tests + one previously failing test), and the number of failing tests decreases to 2.

The inc-repair.sh generates one of the following two kinds of hints: (1) control-flow hint and (2) conditional data-flow hint. A control-flow hint changes the control-flow of the program, whereas a conditional data-flow hint also changes the data-flow of the program. A detailed description is available in Section 6.2 of our [ESEC/FSE-17 paper](http://jooyongyi.com/papers/Yi-ESEC-FSE17.pdf).

In the running example, the first two rows (inst 0 and 1) indicate that Angelix succeeds to generate control-flow hints (ag_cf values are 0). In the third repair session, Prophet succeeds to generate a conditional data-flow hint --- proper data-flow change is found by Prophet (pr_df value is 0), and a proper guard condition for that data-flow change is also found by Prophet (pr_ref value is 0).

The following is the description of each column:

   * **lab**: lab ID
   * **prob**: problem ID
   * **prog**: program ID
   * **inst**: instance number of tool invocation, starting from 0. 
   * **pos**: the number of positive (passing) tests
   * **neg**: the number of negative (failing) tests
   * **ww**: 0 when AE succeeds to generate a data-flow hint; 1 when AE fails to generate a data-flow hint.
   * **ga**: 0 when GenProg succeeds to generate a data-flow hint; 1 when GenProg fails to generate a data-flow hint.
   * **pr_df**: 0 when Prophet succeeds to generate the data-flow hint module of a conditional data-flow hint; 1 when GenProg fails to generate such a module. "df" stands for data-flow.
   * **ag_df**: 0 when Angelix succeeds to generate a data-flow hint module of a conditional data-flow hint; 1 when Angelix fails to generate such a module.
   * **ag_cf**: 0 when Angelix succeeds to generate a control-flow hint; 1 when Angelix fails to generate a control-flow hint. "cf" stands for control-flow.
   * **pr_cf**: 0 when Prophet succeeds to generate a control-flow hint; 1 when Prophet fails to generate a control-flow hint.
   * **ag_ref**: 0 when Angelix succeeds to generate a control-flow hint module of a conditional data-flow hint; 1 when Angelix fails to generate such a module.
   * **pr_ref**: 0 when Angelix succeeds to generate a control-flow hint module of a conditional data-flow hint; 1 when Angelix fails to generate such a module.         
   * **rep_ok**: 0 when a repair is found; 1 when a repair is not found
   * **time**: overall time (seconds) taken to generate a repair

### Where are generated repairs/hints? ###   

In the Docker container (jayyi/itsp:0.0), repairs/hints are stored under directory /ITSP-experiments. More specifically, the results of base.sh and inc-repair.sh are stored under /ITSP-experiments/dataset-base and /ITSP-experiments/dataset-inc-repair, respectively. To search for generated repairs/hints, type the following:

    # To search for generated repairs in /ITSP-experiments/dataset-base
    > cd /ITSP-experiments/dataset-base && find -regextype posix-extended -regex '.*_buggy/[[:digit:]]+_buggy-[[:digit:]]\.c$' | sort
    ./Lab-5/2867/277945_buggy/277945_buggy-0.c
    ./Lab-5/2867/277945_buggy/277945_buggy-1.c

    # To search for generated hints in /ITSP-experiments/dataset-inc-repair
    > cd /ITSP-experiments/dataset-inc-repair && find -regextype posix-extended -regex '.*_buggy/[[:digit:]]+_buggy-[[:digit:]]\.c$' | sort
    ./Lab-10/3239/303888_buggy/303888_buggy-0.c
    ./Lab-10/3239/303888_buggy/303888_buggy-1.c
    ./Lab-10/3239/303888_buggy/303888_buggy-2.c
    ./Lab-10/3239/303888_buggy/303888_buggy-3.c    
    ./Lab-10/3239/303888_buggy/303888_buggy-4.c
    
File XXX_buggy-0.c is the initial buggy program, and XXX_bugggy-*n*.c (where *n* > 0) is the *n*-th repair/hint generated based on XX_buggy-*(n-1)*.c.

## Experimental Results ##

Our experimental results are available in [experiment/cache](https://github.com/jyi/ITSP/tree/master/experiment/cache). 

   1. result-base: our experimental result from base.sh
   2. result-inc-repair:  our experimental result from inc-repair.sh
   
**N.B.** Some APR tools have randomness in their repair process. Also, parallel use of multiple repair tools introduces one more layer of randomness (there is no guarantee that one repair tool always finds a repair faster than the other tools). Different results may be produced at each experiment, because of this randomness. 

Meanwhile, [experiment/cache/analysis/analysis.R](https://github.com/jyi/ITSP/tree/master/experiment/cache/analysis/analysis.R) can be used to reproduce the results in our [ESEC/FSE-17 paper](http://jooyongyi.com/papers/Yi-ESEC-FSE17.pdf).

```
> Rscript analysis.R
```    


***

## User Study Materials ##
Refer to Section 7.3 of the [ESEC/FSE-17 paper](http://jooyongyi.com/papers/Yi-ESEC-FSE17.pdf) for more details.
All the files talked about in this section are present in the *ITSP/user_study* directory.

**Student Bug Fix Task**:
**250+** first year undergraduates volunteered to find and fix bugs such that all the test-cases pass 
- *studentTask_SubmissionList.csv* - Contains the list of **5**  buggy submissions  chosen from our [dataset](https://github.com/jyi/ITSP#dataset-student-programs) for this task

**Teaching Assistant (TA) Grading Task**:
A total of 38 TAs volunteered for the TA grading task, out of which **37** finally turned up and were assigned tasks (TA-21 did not appear) 
- *taTask_SubmissionList.csv* - Contains the list of **43**  buggy submissions which were randomly chosen from our [dataset](https://github.com/jyi/ITSP#dataset-student-programs) for this task

**TA Survey**: 
*  *Survey-Pre-Repair (Questions).pdf* - Contains the questions asked to TAs before grading tasks were assigned
*  *Survey-Post-Repair (Questions).pdf* - Contains the questions asked to TAs after completion of all grading tasks
*  *Survey-Pre-Repair (Responses).csv* - Contains 35 responses of TAs to Pre-Repair questions
    *  TA-17 and TA-25 did not fill up the Pre-Repair survey (2 out of 37)
*  *Survey-Post-Repair (Responses).csv* - Contains 35 responses of TAs to Post-Repair questions
    *  TA-4 and TA-20 did not fill up the Post-Repair survey (2 out of 37)
