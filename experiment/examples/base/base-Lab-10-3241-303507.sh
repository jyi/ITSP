#!/bin/bash

rm -f result-base
cp result-base.template result-base

export submissions_root="/ITSP-experiments/dataset-base"
export test_dir=${submissions_root}/test
export prog_name="prog"
export result_file=$(pwd)/result-base
export wrapper_name="wrapper-repair"
export repair_src_name="repair"
export ref_dir="ref"
export repair_makefile="Makefile.repair"
export ww_session_prefix="ww-session"
export ga_session_prefix="ga-session"
export ag_session_prefix="ag-session"
export pr_session_prefix="pr-session"
export succeed_file="succeed"
export fail_file="failure"
export angelix_pid_log_file="angelix_pid.log"
export test_angelix_pid_log_file="test_angelix_pid.log"

# prophet files
export pr_revision_file="revision.log"
export pr_run_conf_file="run.conf"
export pr_config_file="prophet.conf"
export pr_test_script="test.py"
export pr_run_script="run.sh"
export pr_workdir="workdir"

# angelix params
export tool_timeout=900
export klee_timeout=300
export klee_max_forks=400
export solver_timeout=600
export synthesis_timeout=300000
export test_timeout=10


function safe_pushd () {
    local target=$1

    if pushd $target &> /dev/null; then
        return 0
    else
        echo "[*] failed to push to $target"
        return 1
    fi
}
export -f safe_pushd

function safe_rm () {
    local flag=$1
    local target=$2

    if [[ $target =~ ^[a-zA-Z0-9][a-zA-Z0-9/\_\-]*$ ]]; then
        rm "$flag" "$target" && return 0
    else
        echo "[Error] Did not remove $target"
        return 1
    fi
}
export -f safe_rm

function write_to_file () {
    local file=$1
    local line=$2

    echo -e "$line" >> $file
}
export -f write_to_file

function create_pr_test_script () {
    local prob_id=$1

    rm -f ${pr_test_script} && touch ${pr_test_script}
    cat <<EOF >> ${pr_test_script}
#!/usr/bin/env python
from sys import argv
from os import system
import getopt

if __name__ == "__main__":
    if len(argv) < 4:
        print "Usage: php-tester.py <src_dir> <test_dir> <work_dir> [cases]";
        exit(1);

    opts, args = getopt.getopt(argv[1:], "p:");
    profile_dir = "";
    for o, a in opts:
        if o == "-p":
            profile_dir = a;

    src_dir = args[0];
    test_dir = args[1];
    work_dir = args[2];
    if profile_dir == "":
        cur_dir = src_dir;
    else:
        cur_dir = profile_dir;
    if len(args) > 3:
        ids = args[3:];
        for i in ids:
            cmd = "timeout 1 " + cur_dir + "/prog < " + test_dir + "/in.${prob_id}."+ i + ".txt 1> __out";
            ret = system(cmd);
            if (ret == 0):
                cmd = "diff -ZB __out " + test_dir + "/out.${prob_id}." + i + ".txt 1> /dev/null";
                ret = system(cmd);
                if (ret == 0):
                    print i,
            system("rm -rf __out");
        print;
EOF
    chmod +x ${pr_test_script}
}
export -f create_pr_test_script

function create_revision_log () {
    local prob_id=$1
    local prog_id=$2
    local inst=$3
    local basic_test_script=$4

    poses=($(grep -P "^\tp" ${basic_test_script} | cut -d"|" -f1 | cut -d"<" -f2 | sed -e "s/.txt//g" | sed -e "s?test/in.${prob_id}.??g" | tr -d "\n"))
    negs=($(grep -P "^\tn" ${basic_test_script} | cut -d"|" -f1 | cut -d"<" -f2 | sed -e "s/.txt//g" | sed -e "s?test/in.${prob_id}.??g" | tr -d "\n"))

    rm -f ${pr_revision_file} &> /dev/null
    touch ${pr_revision_file} &> /dev/null
    write_to_file ${pr_revision_file} "-"
    write_to_file ${pr_revision_file} "-"
    write_to_file ${pr_revision_file} "Diff Cases: Tot ${#negs[@]}"
    negs_line="${negs[@]}"
    write_to_file ${pr_revision_file} "${negs_line}"

    write_to_file ${pr_revision_file} "Positive Cases: Tot ${#poses[@]}"
    poses_line="${poses[@]}"
    write_to_file ${pr_revision_file} "${poses_line}"
}
export -f create_revision_log

function create_pr_run_conf () {
    local src_dir=$1

    rm -f ${pr_run_conf_file} &> /dev/null
    touch ${pr_run_conf_file} &> /dev/null
    write_to_file ${pr_run_conf_file} "revision_file=${pr_revision_file}"
    write_to_file ${pr_run_conf_file} "src_dir=${src_dir}"
    write_to_file ${pr_run_conf_file} "test_dir=test"
    write_to_file ${pr_run_conf_file} "build_cmd=${PROPHET_TOOLS_DIR}/simple-build.py"
    write_to_file ${pr_run_conf_file} "test_cmd=${pr_test_script}"
    write_to_file ${pr_run_conf_file} "localizer=profile"
    write_to_file ${pr_run_conf_file} "single_case_timeout=1"
}
export -f create_pr_run_conf

function create_pr_Makefile () {
    local prog_id=$1

    rm -f Makefile
    touch Makefile
    write_to_file Makefile "prog: ${prog_id}.c"
    write_to_file Makefile "$(printf "\tgcc -std=c99 -c ${prog_id}.c -o ${prog_id}.o")"
    write_to_file Makefile "$(printf "\tgcc -std=c99 -o ${prog_name} ${prog_id}.o -lm")"
}
export -f create_pr_Makefile

function create_gp_Makefile () {
    local prog_id=$1
    rm -f Makefile
    touch Makefile
    write_to_file Makefile "all:"
    write_to_file Makefile "$(printf "\tgcc -std=c99 -o %s %s" "${prog_name}" "${prog_id}.c -lm")"
}
export -f create_gp_Makefile

function create_repair_Makefile () {
    rm -f ${repair_makefile}
    touch ${repair_makefile}
    write_to_file ${repair_makefile} "all:"
    write_to_file ${repair_makefile} "$(printf "\tgcc -std=c99 -o repair repair.c -lm")"
}
export -f create_repair_Makefile

function create_ag_Makefile() {
    local flags=$1

    rm -f Makefile
    touch Makefile
    write_to_file Makefile "CC=gcc"
    write_to_file Makefile "CFLAGS=${flags}"
    write_to_file Makefile ""
    write_to_file Makefile "all:"
    write_to_file Makefile "$(printf "\t\$(CC) \$(CFLAGS) -c %s -o %s" "${wrapper_name}.c" "${wrapper_name}.o")"
    write_to_file Makefile "$(printf "\t\$(CC) \$(CFLAGS) -c %s -o %s" "${repair_src_name}.c" "${repair_src_name}.o")"
    write_to_file Makefile "$(printf "\t\$(CC) \$(CFLAGS) %s %s -o %s -lm" "${wrapper_name}.o" "${repair_src_name}.o" "${wrapper_name}")"
    write_to_file Makefile ""
    write_to_file Makefile "clean:"
    write_to_file Makefile "$(printf "\trm -f %s %s %s" "${wrapper_name}" "${wrapper_name}.o" "${repair_src_name}.o")"
}
export -f create_ag_Makefile

function create_gp_ww_config() {
    local prog_id=$1
    local inst=$2
    local test_script=$3
    local pos_test=$4
    local neg_test=$5

    local gp_config_file="gp-ww-${inst}.config"

    rm -f ${gp_config_file} &> /dev/null
    touch ${gp_config_file} &> /dev/null
    write_to_file ${gp_config_file} "$(printf "%sprogram %s.c" "--" "${prog_id}")"
    write_to_file ${gp_config_file} "$(printf "%scompiler gcc" "--")"
    write_to_file ${gp_config_file} "$(printf "%scompiler-command __COMPILER_NAME__ -o __EXE_NAME__ __SOURCE_NAME__ __COMPILER_OPTIONS__ -lm 2> /dev/null" "--")"
    write_to_file ${gp_config_file} "$(printf "%ssearch ww" "--")"
    write_to_file ${gp_config_file} "--no-rep-cache"
    write_to_file ${gp_config_file} "--no-test-cache"
    # write_to_file ${gp_config_file} "--fault-scheme uniform"
    write_to_file ${gp_config_file} "--add-guard"
    write_to_file ${gp_config_file} "$(printf "%slabel-repair" "--")"
    write_to_file ${gp_config_file} "$(printf "%spos-tests ${pos_test}" "--")"
    write_to_file ${gp_config_file} "$(printf "%sneg-tests ${neg_test}" "--")"
    write_to_file ${gp_config_file} "--test-script ./${test_script}"

    echo ${gp_config_file}
}
export -f create_gp_ww_config

function create_gp_ga_config () {
    local prog_id=$1
    local inst=$2
    local test_script=$3
    local pos_test=$4
    local neg_test=$5

    local gp_config_file="gp-ga-${inst}.config"

    rm -f ${gp_config_file} &> /dev/null
    touch ${gp_config_file} &> /dev/null
    write_to_file ${gp_config_file} "$(printf "%sprogram %s.c" "--" "${prog_id}")"
    write_to_file ${gp_config_file} "$(printf "%scompiler gcc" "--")"
    write_to_file ${gp_config_file} "$(printf "%scompiler-command __COMPILER_NAME__ -o __EXE_NAME__ __SOURCE_NAME__ __COMPILER_OPTIONS__ -lm 2> /dev/null" "--")"
    write_to_file ${gp_config_file} "$(printf "%stest-command __TEST_SCRIPT__ __EXE_NAME__ __TEST_NAME__ __PORT__ __SOURCE_NAME__ __FITNESS_FILE__ 2> /dev/null" "--")"
    write_to_file ${gp_config_file} "$(printf "%ssearch ga" "--")"
    write_to_file ${gp_config_file} "--no-rep-cache"
    write_to_file ${gp_config_file} "--no-test-cache"
    # write_to_file ${gp_config_file} "--fault-scheme uniform"
    write_to_file ${gp_config_file} "$(printf "%slabel-repair" "--")"
    write_to_file ${gp_config_file} "$(printf "%spos-tests ${pos_test}" "--")"
    write_to_file ${gp_config_file} "$(printf "%sneg-tests ${neg_test}" "--")"
    write_to_file ${gp_config_file} "$(printf "%sseed 560680701" "--")"
    write_to_file ${gp_config_file} "$(printf "%sminimization" "--")"
    # write_to_file ${gp_config_file} "$(printf "%sswapp 0.0" "--")"
    # write_to_file ${gp_config_file} "$(printf "%sappp 0.5" "--")"
    # write_to_file ${gp_config_file} "$(printf "%sdelp 0.5" "--")"
    # write_to_file ${gp_config_file} "$(printf "%scrossp 0.0" "--")"
    write_to_file ${gp_config_file} "$(printf "%spopsize 20" "--")"
    write_to_file ${gp_config_file} "$(printf "%sgenerations 10" "--")"
    write_to_file ${gp_config_file} "$(printf "%sallow-coverage-fail" "--")"
    write_to_file ${gp_config_file} "--test-script ./${test_script}"

    echo ${gp_config_file}
}
export -f create_gp_ga_config

function prepare_tests() {
    local prob_id=$1
    rm -rf test
    mkdir -p test
    cp ${test_dir}/in.${prob_id}.* test
    cp ${test_dir}/out.${prob_id}.* test
}

function is_positive_test() {
    local prog=$1
    local in_file=$2
    local out_file=$3
    local result

    result=$(timeout 1s ${prog} < ${in_file} | diff -ZB ${out_file} -)
    if [[ $result == "" ]]; then
        echo 0
    else
        echo 1
    fi
}

function create_basic_test_script() {
    local prog_id=$1
    local script=$2
    local __num_of_pos=$3
    local __num_of_neg=$4

    rm -f ${script}
    touch ${script}
    write_to_file ${script} "#!/bin/bash"
    write_to_file ${script} "# \$1 = EXE"
    write_to_file ${script} "# \$2 = test name"
    write_to_file ${script} "# \$3 = port"
    write_to_file ${script} "# \$4 = source name"
    write_to_file ${script} "# \$5 = single-fitness-file name"
    write_to_file ${script} "# exit 0 = success"
    write_to_file ${script} "ulimit -t 1"
    write_to_file ${script} "echo \$1 \$2 \$3 \$4 \$5 >> testruns.txt"
    write_to_file ${script} "case \$2 in"

    pos_count=0
    neg_count=0
    local test_id
    for in_file in test/in.*; do
        local out_file=$(echo ${in_file} | sed -e "s/in/out/g")
        is_pos=$(is_positive_test "./${prog_name}" ${in_file} ${out_file})
        if [[ ${is_pos} == 0 ]]; then
            pos_count=$((pos_count+1))
            test_id=$(printf "p%s" ${pos_count})
        else
            neg_count=$((neg_count+1))
            test_id=$(printf "n%s" ${neg_count})
        fi
        write_to_file ${script} "$(printf "\t%s) \$1 < %s | diff -ZB %s - &> /dev/null && exit 0 ;;" "${test_id}" "${in_file}" "${out_file}")"
    done

    write_to_file ${script} "esac"
    write_to_file ${script} "exit 1"
    chmod +x ${script}

    eval $__num_of_pos=${pos_count}
    eval $__num_of_neg=${neg_count}
}

function create_ag_test_script() {
    local basic_test_script=$1
    local script=$2

    rm -f ${script}
    touch ${script}

    #########################################
    # collect positive and negative tests
    #########################################
    IFS_BAK=${IFS}
    IFS="
"
    poses=($(grep -P "^\tp" ${basic_test_script}))
    negs=($(grep -P "^\tn" ${basic_test_script}))
    IFS=${IFS_BAK}

    write_to_file ${script} "#!/bin/bash"
    write_to_file ${script} "# \$1 = test name"
    write_to_file ${script} "# exit 0 = success"
    write_to_file ${script} "pid_log_file=${test_angelix_pid_log_file}"
    write_to_file ${script} "echo \"[${script}] pwd: \$(pwd)\""
    write_to_file ${script} "# update ANGELIX_RUN (add timeout)"
    write_to_file ${script} "if [[ ! -z \${ANGELIX_RUN} ]]; then"
    write_to_file ${script} "    if [[ \${ANGELIX_RUN} == \"angelix-run-test\" ]]; then"
    write_to_file ${script} "        ANGELIX_RUN=\"timeout 2 angelix-run-test\""
    write_to_file ${script} "    fi"
    write_to_file ${script} "    if [[ \${ANGELIX_RUN} == \"angelix-run-klee\" ]]; then"
    write_to_file ${script} "        ANGELIX_RUN=\"timeout ${klee_timeout} angelix-run-klee\""
    write_to_file ${script} "    fi"
    write_to_file ${script} "fi"
    write_to_file ${script} "case \$1 in"

    for idx in $(seq 0 $((${#poses[@]} - 1))); do
        line=$(echo ${poses[$idx]} | sed -e "s?\$1?\${ANGELIX_RUN:-timeout 1} ./${wrapper_name}?g")
        line=$(echo $line | sed -e "s?test/?../../test/?g")
        line=$(echo $line | sed -e "s?| diff -ZB??g")
        line=$(echo $line | sed -e "s?- \&\&?\&\&?g")
        write_to_file ${script} "$(printf "\t$line")"
    done
    for idx in $(seq 0 $((${#negs[@]} - 1))); do
        line=$(echo ${negs[$idx]} | sed -e "s?\$1?\${ANGELIX_RUN:-timeout 1} ./${wrapper_name}?g")
        line=$(echo $line | sed -e "s?test/?../../test/?g")
        line=$(echo $line | sed -e "s?| diff -ZB??g")
        line=$(echo $line | sed -e "s?- \&\&?\&\&?g")
        write_to_file ${script} "$(printf "\t$line")"
    done

    write_to_file ${script} "esac"
    write_to_file ${script} "exit 1"
    chmod +x ${script}
}
export -f create_ag_test_script

function create_gp_test_script () {
    local prog_id=$1
    local basic_test_script=$2
    local script=$3

    rm -f ${script}
    touch ${script}

    #########################################
    # collect positive and negative tests
    #########################################
    IFS_BAK=${IFS}
    IFS="
"
    poses=($(grep -P "^\tp" ${basic_test_script}))
    negs=($(grep -P "^\tn" ${basic_test_script}))
    IFS=${IFS_BAK}

    write_to_file ${script} "#!/bin/bash"
    write_to_file ${script} "# \$1 = EXE"
    write_to_file ${script} "# \$2 = test name"
    write_to_file ${script} "# \$3 = port"
    write_to_file ${script} "# \$4 = source name"
    write_to_file ${script} "# \$5 = single-fitness-file name"
    write_to_file ${script} "# exit 0 = success"
    write_to_file ${script} "echo \$1 \$2 \$3 \$4 \$5 >> testruns.txt"
    write_to_file ${script} "case \$2 in"

    # positive tests
    for idx in $(seq 0 $((${#poses[@]} - 1))); do
        line=$(echo ${poses[$idx]})
        pos_test_id=$(echo $line | cut -d")" -f1)
        pos_test_cmd=$(echo $line | cut -d")" -f2)
        write_to_file ${script} "$(printf "\t${pos_test_id}) timeout 1 ${pos_test_cmd}")"
    done

    # negative test
    for idx in $(seq 0 $((${#negs[@]} - 1))); do
        line=$(echo ${negs[$idx]})
        test_id=$(echo $line | cut -d")" -f1)
        test_cmd=$(echo $line | cut -d")" -f2)
        write_to_file ${script} "$(printf "\t${test_id}) timeout 1 ${test_cmd}")"
    done

    write_to_file ${script} "esac"
    write_to_file ${script} "exit 1"
    chmod +x ${script}
}
export -f create_gp_test_script

function create_clean_script() {
    local script_name="clean"
    rm -f ${script_name}
    touch ${script_name}
    write_to_file ${script_name} "rm -f *.cache"
    write_to_file ${script_name} "rm -rf *.fitness"
    write_to_file ${script_name} "rm -f coverage.*"
    write_to_file ${script_name} "rm -f repair.debug.*"
    write_to_file ${script_name} "rm -f repair.sanity.c"
    write_to_file ${script_name} "rm -f repair.c"
    write_to_file ${script_name} "rm -f coverage"
    write_to_file ${script_name} "rm -f testruns.txt"
    write_to_file ${script_name} "rm -rf Minimization_Files"
    chmod +x ${script_name}
}

function run_gp () {
    local gp_config_file=$1
    local gp_log_file=$2
    local __found_repair=$3
    local __gp_time=$4

    eval $__gp_time=0

    ./clean
    START_TIME=$SECONDS
    timeout ${tool_timeout} repair ${gp_config_file} &> /dev/null
    ELAPSED_TIME=$(($SECONDS - $START_TIME))
    eval $__gp_time=$(($SECONDS - $START_TIME))
    rm -f ${gp_log_file} &> /dev/null
    mv repair.debug.* ${gp_log_file} &> /dev/null

    # check to see if we've generated a repair, pass if we do
    if [ -e repair.c ]
    then
        eval $__found_repair=0
    else
        eval $__found_repair=1
    fi
}
export -f run_gp

function run_prophet () {
    local __found_repair=$1
    local __pr_time=$2
    local prophet_log=$3

    eval $__pr_time=0

    cat <<EOF >> ${pr_config_file}
${pr_run_conf_file} -r ${pr_workdir} -consider-all -feature-para ${PROPHET_FEATURE_PARA} -replace-ext -cond-ext
EOF

    START_TIME=$SECONDS
    timeout ${tool_timeout} safe-prophet `cat ${pr_config_file}` &> ${prophet_log}
    eval $__pr_time=$(($SECONDS - $START_TIME))

    # hack: workaround for the docker problem
    if [[ -e workdir/profile_localization.res && $(cat workdir/profile_localization.res | wc -l) == 0 ]]; then
        rm -rf workdir
        START_TIME=$SECONDS
        timeout ${tool_timeout} safe-prophet `cat ${pr_config_file}` &> ${prophet_log}
        eval $__pr_time=$(($SECONDS - $START_TIME))
    fi

    # check to see if we've generated a repair, pass if we do
    if [ -s __fixed*.c ]
    then
        echo "[pr] found a repair"
        cp __fixed*.c repair.c
        eval $__found_repair=0
    else
        echo "[pr] failed to find a repair"
        eval $__found_repair=1
    fi
}
export -f run_prophet

function run_angelix () {
    local __guard_ok=$1
    local __tests_ok=$2
    local __found_repair=$3
    local __ag_time=$4
    local found_gp_repair=$5
    local ag_test_script=$6
    local ag_config_file=$7
    local gp_repair_dir=$8
    local angelix_log=$9

    eval $__guard_ok=1
    eval $__tests_ok=1
    eval $__found_repair=1
    eval $__ag_time=0


    if [[ ${found_gp_repair} == 0 ]]; then
        # collect lines
        lines=($(grep -n "if (1 != 0)\|if (1 == 0)" ${gp_repair_dir}/${repair_src_name}.c | cut -d':' -f1))
        if [[ -z $lines ]]; then
            eval $__guard_ok=1 && return
        else
            eval $__guard_ok=0
        fi
    else
        eval $__guard_ok=0
    fi

    # collect positive and negative tests
    pos_tests=($(grep -P "^\tp" ${ag_test_script} | cut -d$'\t' -f2 | cut -d')' -f1))
    neg_tests=($(grep -P "^\tn" ${ag_test_script} | cut -d$'\t' -f2 | cut -d')' -f1))
    if [[ -z ${pos_tests} ]]; then
        eval $__tests_ok=1 # && return
    else
        eval $__tests_ok=0
    fi

    # prepare configuration file
    rm -f ${ag_config_file}
    touch ${ag_config_file}
    cat <<EOF >> ${ag_config_file}
${gp_repair_dir} ${repair_src_name}.c ${ag_test_script} ${pos_tests[@]} ${neg_tests[@]} \
        --golden ref --defect if-conditions assignments loop-conditions \
        --synthesis-levels alternatives integer-constants variables extended-arithmetic extended-logic extended-inequalities mixed-conditional conditional-arithmetic --use-nsynth \
        --synthesis-func-params --synthesis-global-vars --synthesis-used-vars \
        --init-uninit-vars \
        --klee-ignore-errors --ignore-infer-errors \
        --klee-max-forks ${klee_max_forks} --klee-max-depth 200 --max-angelic-paths 10 \
        --klee-timeout ${klee_timeout} --synthesis-timeout ${synthesis_timeout} \
        --test-timeout ${test_timeout} --timeout ${tool_timeout} --verbose
EOF

    if ! [[ -e ${ag_config_file} ]]; then
        echo "[AG] ${ag_config_file} does not exist" && eval $__found_repair=1 && return
    fi

    rm -f *.patch
    rm -f ${angelix_log}
    local angelix_timeout=$((tool_timeout+10))
    ulimit -n 4000 # increase the maximum number of open file descriptors
    START_TIME=$SECONDS
    timeout ${angelix_timeout} angelix `cat ${ag_config_file}` &> ${angelix_log} & pid=$!
    echo $pid > ${angelix_pid_log_file}
    wait $pid
    eval $__ag_time=$(($SECONDS - $START_TIME))

    grep -q "No negative test exists" ${angelix_log} && echo "[AG] No negative test exists" && eval $__found_repair=1 && return

    # check to see if we've generated a repair, pass if we do
    if [ -s *.patch ]
    then
        eval $__found_repair=0
    else
        eval $__found_repair=1
    fi
}
export -f run_angelix

function create_extract_source_awk() {
    local awk_file=$1

    rm -f ${awk_file}
    cat <<EOF >> ${awk_file}
BEGIN {
    skip=1
}

/WRAPPER CODE BEGINS/ || /DUMMY CODE BEGINS/ {
    skip=0;
}

skip==1 {
    if (\$0 !~ /__dummy_var/ && \$0 !~ /\/\* missing proto \*\//) {
        sub("^main_internal", "main", \$0);
        gsub("sprintf \(out_buffer \+ strlen \(out_buffer\),", "printf (", \$0);
        print
    }
}

/WRAPPER CODE ENDS/ || /DUMMY CODE ENDS/ {
    skip=1;
}

END   {}
EOF
}
export -f create_extract_source_awk

function create_extract_include_awk() {
    local awk_file=$1

    rm -f ${awk_file}
    cat <<EOF >> ${awk_file}
BEGIN {}

/#include</ {
    print
}

END   {}
EOF
}
export -f create_extract_include_awk

function create_remove_conflict_decl_awk() {
    local awk_file=$1

    rm -f ${awk_file}
    cat <<EOF >> ${awk_file}
BEGIN {}

!/\/\* missing proto \*\// && !/^extern/ {
    print
}

END   {}
EOF
}
export -f create_remove_conflict_decl_awk

function create_remove_dummy_var_awk () {
    local awk_file=$1

    rm -f ${awk_file}
    cat <<EOF >> ${awk_file}
BEGIN {}

!/__dummy_var/ {
    print
}

END   {}
EOF
}
export -f create_remove_dummy_var_awk

function create_add_p1_awk () {
    local awk_file=$1

    rm -f ${awk_file}
    cat <<EOF >> ${awk_file}
BEGIN {}

/^case \\\$2 in/ {
    print
    print "	p1) exit 0 ;;"
}

!/^case \\\$2 in/ {
    print
}

END   {}
EOF
}
export -f create_add_p1_awk

function create_wrapper_file() {
    local org_file=$1

    if [[ ! ( -f ${org_file} ) ]]; then
        echo "${org_file} does not exist"
        return
    fi

    rm -f ${wrapper_name}.c
    touch ${wrapper_name}.c
    cat <<EOF >> ${wrapper_name}.c
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#ifndef ANGELIX_OUTPUT
#define ANGELIX_OUTPUT(type, expr, id) expr
#endif

FILE *out_file;
char out_buffer[1000];

int main_internal (void);

char *trim_trail_ws(char *str)
{
  char *end;

  end = str + strlen(str) - 1;
  while(end > str && isspace(*end)) end--;

  *(end+1) = 0;

  return str;
}

int compare_strings(char a[], char b[])
{
  int c = 0;

  while (a[c] == b[c]) {
    if (a[c] == '\0' || b[c] == '\0')
      break;
    c++;
  }

  if ((a[c] == '\0') && (b[c] == '\0')) {
    return 0;
  }
  else {
    return -1;
  }
}

int main(int argc, char *argv[]) {
  int max = 100;
  char buf1[max];
  char buf2[max];
  FILE *file;
  char *cur;

  printf("[wrapper] test-repair started\n");

  main_internal();
  printf("\n[wrapper] repair_main done\n");
  fflush(stdout);

  out_file = fopen("./out", "w");
  if (out_file == NULL) {
    printf("failed to open out\n");
    fflush(stdout);
    exit(-1);
  }
  fprintf(out_file, "%s", out_buffer);
  fclose(out_file);

  /* diff */
  file = fopen("./out", "r");
  cur = buf1;
  while (fgets(cur, max, file) != NULL) {
    cur = buf1 + strlen(buf1);
  }
  fclose(file);

  file = fopen(argv[1], "r");
  cur = buf2;
  while (fgets(cur, max, file) != NULL) {
    cur = buf2 + strlen(buf2);
  }
  fclose(file);

  trim_trail_ws(buf1);
  trim_trail_ws(buf2);
  if (compare_strings(buf1, buf2) == 0) {
    printf("%d\n", ANGELIX_OUTPUT(int, 0, "result"));
    printf("Pass\n");
    fflush(stdout);
    return 0;
  } else {
    printf("%d\n", ANGELIX_OUTPUT(int, 1, "result"));
    printf("Fails\n");
    fflush(stdout);
    return 1;
  }
}
EOF

    rm -f ${repair_src_name}.c
    touch ${repair_src_name}.c
    cat <<EOF >> ${repair_src_name}.c
// WRAPPER CODE BEGINS
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#ifndef ANGELIX_OUTPUT
#define ANGELIX_OUTPUT(type, expr, id) expr
#endif

char out_buffer[1000];
// WRAPPER CODE ENDS

EOF

    cat ${org_file} >> ${repair_src_name}.c
    indent_option="--line-length1000"
    indent  ${indent_option} ${repair_src_name}.c
    sed -i.bak -E "s/^[ \t]+//g" ${repair_src_name}.c
    sed -i.bak -e "s/^main (void)/main_internal (void)/g" ${repair_src_name}.c
    sed -i.bak -e "s/^main ()/main_internal ()/g" ${repair_src_name}.c
    sed -i.bak -e "s/^printf (/sprintf (out_buffer + strlen(out_buffer), /g" ${repair_src_name}.c
    local adjust_src_awk_file="adjust-src.awk"
    local new_src_file="new_src.c"
    create_remove_conflict_decl_awk ${adjust_src_awk_file}
    awk -f ${adjust_src_awk_file} ${repair_src_name}.c > ${new_src_file}
    mv ${new_src_file} ${repair_src_name}.c
    indent ${indent_option} ${repair_src_name}.c
}
export -f create_wrapper_file

function diagnose_gp_repair_failure() {
    local log_file=$1
    local __gp_ok=$2
    local __fail_reason=$3

    grep -q "sanity check failed" ${log_file} && eval $__gp_ok=1 && \
        eval $__fail_reason="'sanity check failed.'" && return
    grep -q "unexpected coverage result" ${log_file} && eval $__gp_ok=1 && \
        eval $__fail_reason="'unexpected coverage result'" && return
    eval $__fail_reason="'no gp rep'" && eval $__gp_ok=0 && return
}
export -f diagnose_gp_repair_failure

function diagnose_ag_repair_failure() {
    local why_fail=""
    local found_gp_repair=$1
    local angelix_log=$2

    if [[ ${found_gp_repair} == 1 ]]; then
        echo "no gp rep" && return
    fi
    grep -q "No non-error paths explored" ${angelix_log} \
        && echo "No non-error paths explored" && return
    grep -q "synthesis failed" ${angelix_log} && echo "synthesis failed" && return
    grep -q "synthesis returned non-zero code" ${angelix_log} && echo "synthesis returned non-zero" && return
    grep -q "found 0 angelic paths" ${angelix_log} && echo "no angelic path" && return
    grep -q "PermissionError" ${angelix_log} && echo "PermissionError" && return
    echo "other ag error" && return
}
export -f diagnose_ag_repair_failure

function repair_in_parallel () {
    local prob_id=$1
    local prog_id=$2
    local inst=$3
    local basic_test_script=$4
    local ww_test_script=$5
    local num_of_pos=$6
    local num_of_neg=$7
    local repair_mode=$8

    case ${repair_mode} in
        pr)
            local src_dir="src"
            if [[ ${skip_pr} != 0 ]]; then
                local session_dir="${pr_session_prefix}-${inst}"
                rm -rf ${session_dir} && mkdir -p ${session_dir}
                cp ${basic_test_script} ${session_dir}
                cp -r test ${session_dir}

                if safe_pushd "${session_dir}"; then
                    rm -rf ${src_dir} && mkdir -p ${src_dir}
                    cp ../${prog_id}.c ${src_dir}
                    if safe_pushd "${src_dir}"; then
                        create_pr_Makefile ${prog_id}
                        popd &> /dev/null
                    fi
                    create_pr_test_script ${prob_id}
                    create_revision_log ${prob_id} ${prog_id} ${inst} ${basic_test_script}
                    create_pr_run_conf ${src_dir}
                    found_pr_repair=1
                    log_file="prophet-${inst}.log"
                    run_prophet found_pr_repair pr_time ${log_file}
                    popd &> /dev/null
                fi

                if [[ $found_pr_repair == 0 ]]; then
                    echo "[pr] repair succeeded"
                    touch ${session_dir}/${succeed_file}
                    return 1
                else
                    echo "[pr] repair failed"
                    touch ${session_dir}/${fail_file}
                    return 0
                fi
            else
                echo "[pr] skips"
                return 0
            fi
            ;;
        ww)
            if [[ ${skip_gp_ww} != 0 ]]; then
                local session_dir="${ww_session_prefix}-${inst}"
                rm -rf ${session_dir}
                mkdir -p ${session_dir}
                cp ${prog_id}.c ${session_dir}
                cp clean ${session_dir}
                cp ${basic_test_script} ${session_dir}
                cp -r test ${session_dir}

                if safe_pushd "${session_dir}"; then
                    create_gp_test_script ${prog_id} ${basic_test_script} ${ww_test_script}
                    gp_config_file=$(create_gp_ww_config \
                        ${prog_id} ${inst} ${ww_test_script} ${num_of_pos} ${num_of_neg})

                    log_file="gp-ww-${inst}.log"
                    gp_ok=0
                    found_gp_repair=1
                    run_gp ${gp_config_file} ${log_file} found_gp_repair gp_ww_time
                    if [[ $found_gp_repair == 1 ]]; then
                        diagnose_gp_repair_failure ${log_file} gp_ok fail_reason
                        touch ${fail_file}
                    else
                        touch ${succeed_file}
                    fi

                    popd &> /dev/null
                fi

                if [[ $found_gp_repair == 0 ]]; then
                    echo "[ww] repair succeeded"
                    return 1
                else
                    echo "[ww] repair failed"
                    return 0
                fi
            else
                echo "[ww] skips"
                return 0
            fi
            ;;
        ga)
            if [[ ${skip_gp_ga} != 0 ]]; then
                local session_dir="${ga_session_prefix}-${inst}"
                rm -rf ${session_dir}
                mkdir -p ${session_dir}
                cp ${prog_id}.c ${session_dir}
                cp clean ${session_dir}
                cp ${basic_test_script} ${session_dir}
                cp -r test ${session_dir}

                if safe_pushd "${session_dir}"; then
                    create_gp_test_script ${prog_id} ${basic_test_script} ${ww_test_script}
                    local ga_test_script="test-ga-${inst}.sh"
                    if [[ ${num_of_pos} == 0 ]]; then
                        local add_p1_awk_file="add_p1.awk"
                        create_add_p1_awk ${add_p1_awk_file}
                        awk -f ${add_p1_awk_file} ${ww_test_script} > ${ga_test_script}
                        chmod +x ${ga_test_script}

                        gp_config_file=$(create_gp_ga_config \
                            ${prog_id} ${inst} ${ga_test_script} 1 ${num_of_neg})
                    else
                        cp ${ww_test_script} ${ga_test_script}
                        gp_config_file=$(create_gp_ga_config \
                            ${prog_id} ${inst} ${ga_test_script} ${num_of_pos} ${num_of_neg})
                    fi
                    log_file="gp-ga-${inst}.log"
                    gp_ok=0
                    found_gp_repair=1
                    run_gp ${gp_config_file} ${log_file} found_gp_repair gp_ga_time
                    if [[ $found_gp_repair == 1 ]]; then
                        diagnose_gp_repair_failure ${log_file} gp_ok fail_reason
                        touch ${fail_file}
                    else
                        touch ${succeed_file}
                    fi
                    popd &> /dev/null
                fi

                if [[ $found_gp_repair == 0 ]]; then
                    echo "[ga] repair succeeded"
                    return 1
                else
                    echo "[ga] repair failed"
                    return 0
                fi
            else
                echo "[ga] skips"
                return 0
            fi
            ;;
        ag)
            if [[ ${skip_ag} != 0 ]]; then
                local session_dir="${ag_session_prefix}-${inst}"
                rm -rf ${session_dir}
                mkdir -p ${session_dir}
                cp ${prog_id}.c ${session_dir}
                cp ${prog_id}-${inst}.c ${session_dir}
                cp clean ${session_dir}
                cp ${basic_test_script} ${session_dir}
                cp -r test ${session_dir}

                if safe_pushd "${session_dir}"; then
                    repair_file="${prog_id}-${inst}.c"
                    if ! [[ -e ${repair_file} ]]; then
                        echo "${repair_file} does not exist"
                    fi
                    if [[ -e ${repair_file} ]]; then
                        safe_rm "-rf" ${gp_repair_dir} && mkdir -p ${gp_repair_dir}
                        safe_rm "-rf" ${ref_dir} && mkdir -p ${ref_dir}
                        ag_test_script="test-angelix-${inst}.sh"
                        create_ag_test_script ${basic_test_script} ${ag_test_script}

                        if safe_pushd "${gp_repair_dir}"; then
                            create_ag_Makefile "-std=c99"
                            create_wrapper_file "../${repair_file}"
                            popd &> /dev/null
                        fi

                        if safe_pushd "${ref_dir}"; then
                            create_ag_Makefile "-std=c99"
                            create_wrapper_file "../../../Main.c"
                            popd &> /dev/null
                        fi

                        guard_ok=1
                        tests_ok=1
                        found_ag_repair=1
                        found_gp_repair=1
                        log_file="angelix-${inst}.log"
                        run_angelix guard_ok tests_ok found_ag_repair ag_start_time \
                            ${found_gp_repair} ${ag_test_script} ${ag_config_file} \
                            ${gp_repair_dir} ${log_file}

                        if [[ ${found_ag_repair} == 0 ]]; then
                            touch ${succeed_file}
                        else
                            touch ${fail_file}
                        fi
                    fi
                    popd &> /dev/null
                fi

                if [[ ${found_ag_repair} == 0 ]]; then
                    echo "[ag] repair succeeded"
                    return 1
                else
                    echo "[ag] repair failed"
                    return 0
                fi
            else
                echo "[ag] skips"
                return 0
            fi
            ;;
    esac
}
export -f repair_in_parallel

function handle () {
    local lab_id=$1
    local prob_id=$2
    local prog_id=$3
    local skip_ag=$4
    local skip_gp_ww=$5
    local skip_gp_ga=$6

    local inst=0
    local num_of_pos=-1
    local num_of_neg=-1

    if safe_pushd "${prog_id}"; then
        cp ${prog_id}.c ${prog_id}.c.org
        popd &> /dev/null
    fi

    for trial in $(seq 0 1); do
        local repair_done=1
        handle_instance $1 $2 $3 $4 $5 $6 $inst repair_done num_of_pos num_of_neg
        echo "repair done at ${inst}: ${repair_done}"
        if [[ $repair_done == 1 ]]; then
            break
        fi
        inst=$((inst+1))
    done
}

function handle_instance () {
    local lab_id=$1
    local prob_id=$2
    local prog_id=$3
    local skip_ag=$4
    local skip_gp_ww=$5
    local skip_gp_ga=$6
    local inst=$7
    local __repair_done=$8
    local __num_of_pos=${9}
    local __num_of_neg=${10}

    ag_start_time=0
    gp_ww_time=0
    gp_ga_time=0
    ag_refine_time=0

    local repair_ok=1
    eval ${__repair_done}=1

    rm -rf /tmp/*    

    if safe_pushd "${prog_id}"; then
        echo "[*] handle ${lab_id}-${prob_id}-${prog_id}-${inst}"

        export basic_test_script="test-${inst}.sh"
        export ww_test_script="test-ww-${inst}.sh"
        export ag_test_script="test-angelix-${inst}.sh"
        export ag_config_file="ag-${inst}.config"

        export gp_repair_dir="gp-repaired-${inst}"

        for trial in $(seq 0 0); do # break in the loop enables early return
            cp ${prog_id}.c ${prog_id}-org-${inst}.c
            cp ${prog_id}.c repair.sanity.c

            local adjust_src_awk_file="rem-dummy-var.awk"
            local new_src_file="new_src.c"
            create_remove_dummy_var_awk ${adjust_src_awk_file}
            awk -f ${adjust_src_awk_file} repair.sanity.c > ${new_src_file}
            mv ${new_src_file} repair.sanity.c
            adjust_src_awk_file="rem-conflic-decl.awk"
            create_remove_conflict_decl_awk ${adjust_src_awk_file}
            awk -f ${adjust_src_awk_file} repair.sanity.c > ${new_src_file}
            mv ${new_src_file} repair.sanity.c
            cp repair.sanity.c repair.sanity-${inst}.c

            cp repair.sanity.c ${prog_id}.c
            cp ${prog_id}.c ${prog_id}-${inst}.c
            create_gp_Makefile ${prog_id}
            rm -f ${prog_name} && make &> /dev/null

            if [[ ! -f ${prog_name} ]]; then
                echo "Failed to compile"
                gp_ok=1
                found_gp_repair=1
                guard_ok=""
                tests_ok=""
                found_ag_repair=""
                fail_reason="Failed to compile"
                break
            else
                create_clean_script
                prepare_tests ${prob_id}
                create_basic_test_script ${prog_id} ${basic_test_script} num_of_pos num_of_neg

                ######################################################
                # Check if there is a negative test
                ######################################################
                IFS_BAK=${IFS}
                IFS="
"
                negs=($(grep -P "^\tn" ${basic_test_script} | sed -e 's/^\tn[0-9]*)//g'))
                IFS=${IFS_BAK}

                if [[ ${#negs[@]} == 0 ]]; then
                    echo "No negative test any more"
                    repair_ok=0
                    break
                fi

                repair_ok=1
                found_gp_repair_ww=""
                found_gp_repair_ga=""
                found_ag_repair=""
                found_pr_repair=""
                local parallel_log_file="parallel-${inst}.log"
                START_TIME=$SECONDS
                parallel --halt 2 repair_in_parallel \
                    ${prob_id} ${prog_id} ${inst} ${basic_test_script} ${ww_test_script} \
                    ${num_of_pos} ${num_of_neg} \
                    ::: "ww" "ga" "ag" "pr" &> ${parallel_log_file}
                time_parallel=$(($SECONDS - $START_TIME))

                #########################
                # kill orphan processes
                #########################
                for trial in $(seq 0 1); do
                    for log_file in $(find ./ -name ${angelix_pid_log_file}); do
                        pid=$(cat ${log_file})
                        kill -9 -$pid &> /dev/null
                    done

                    for log_file in $(find ./ -name ${test_angelix_pid_log_file}); do
                        if [[ ${log_file} == *"/backend/"* ]]; then
                            for pid in $(cat ${log_file}); do
                                pgid=$(ps -eo pid,pgid | grep -e "[[:space:]]${pid}[[:space:]]" | awk {'print $2'})
                                if [[ $pgid != "" ]]; then
                                    kill -9 -${pgid}
                                fi
                            done
                        fi
                    done

                    orphan_pids=$(ps -o ppid,pid,comm,args -www -C klee | grep -e "[[:space:]]1[[:space:]]" | grep ${wrapper_name} | awk {'print $2'})
                    for pid in ${orphan_pids}; do
                        if [[ $pid != "" ]]; then
                            kill -9 $pid
                        fi
                    done

                    sleep 1
                done

                if [ -e "${ag_session_prefix}-${inst}/${succeed_file}" ]; then
                    repair_ok=0
                    found_ag_repair=0
                    echo "[ag] repair succeeded"
                elif [ -e "${ww_session_prefix}-${inst}/${succeed_file}" ]; then
                    repair_ok=0
                    found_gp_repair_ww=0
                    echo "[ww] repair succeeded"
                elif [ -e "${ga_session_prefix}-${inst}/${succeed_file}" ]; then
                    repair_ok=0
                    found_gp_repair_ga=0
                    echo "[ga] repair succeeded"
                elif [ -e "${pr_session_prefix}-${inst}/${succeed_file}" ]; then
                    repair_ok=0
                    found_pr_repair=0
                    echo "[pr] repair succeeded"
                fi

                [ -e "${ww_session_prefix}-${inst}/${fail_file}" ] && found_gp_repair_ww=1
                [ -e "${ga_session_prefix}-${inst}/${fail_file}" ] && found_gp_repair_ga=1
                [ -e "${ag_session_prefix}-${inst}/${fail_file}" ] && found_ag_repair=1
                [ -e "${pr_session_prefix}-${inst}/${fail_file}" ] && found_pr_repair=1
            fi
        done

        echo "repair_ok: ${repair_ok}"
        echo "found_gp_repair_ww: ${found_gp_repair_ww}"
        echo "found_gp_repair_ga: ${found_gp_repair_ga}"
        echo "found_ag_repair: ${found_ag_repair}"
        echo "found_pr_repair: ${found_pr_repair}"

        ###########################
        # prepare the next source
        ###########################
        export repaired_dir="repaired-${inst}"
        if [[ $repair_ok == 0 ]]; then
            fail_reason=""
            eval ${__repair_done}=0

            if [[ ${#negs[@]} -gt 0 ]]; then
                if [[ ${found_gp_repair_ww} == 0 ]]; then
                    cp -r ${ww_session_prefix}-${inst} ${repaired_dir}
                elif [[ ${found_gp_repair_ga} == 0 ]]; then
                    cp -r ${ga_session_prefix}-${inst} ${repaired_dir}
                elif [[ ${found_pr_repair} == 0 ]]; then
                    cp -r ${pr_session_prefix}-${inst} ${repaired_dir}
                elif [[ ${found_ag_repair} == 0 ]]; then
                    cp -r ${ag_session_prefix}-${inst}/.angelix/validation/ ${repaired_dir}
                fi

                if safe_pushd "${repaired_dir}"; then
                    local src_awk_file="extract-source.awk"
                    local inc_awk_file="extract-include.awk"
                    local new_src_file="new_src.c"
                    create_extract_source_awk ${src_awk_file}
                    create_extract_include_awk ${inc_awk_file}
                    awk -f ${inc_awk_file} ../${prog_id}.c.org > ${new_src_file}
                    awk -f ${src_awk_file} ${repair_src_name}.c >> ${new_src_file}
                    # set the next source
                    cp ${new_src_file} ../${prog_id}.c
                    popd &> /dev/null
                fi
            fi
        fi

        eval ${__num_of_pos}=${num_of_pos}
        eval ${__num_of_neg}=${num_of_neg}

        simple_prog_id=$(echo ${prog_id} | sed "s/_buggy//g")
        write_to_file ${result_file} "${lab_id}\t${prob_id}\t${simple_prog_id}\t${inst}\t${num_of_pos}\t${num_of_neg}\t${found_gp_repair_ww}\t${found_gp_repair_ga}\t${found_ag_repair}\t${found_pr_repair}\t${repair_ok}\t${time_parallel}"
        popd &> /dev/null
    fi
}

##########################################################################################

export target_lab_id="Lab-10"
export target_prob_id="3241"
export target_prog_id="303507_buggy"

export skip_ag=1
export skip_gp_ww=1
export skip_gp_ga=1
export skip_pr=1

export skip_done=0

if safe_pushd "${submissions_root}"; then
    Labs=$(ls -1d Lab*/)

    for lab_dir in ${Labs[@]}; do
        lab_id=${lab_dir%/}
        if [[ ! (-z ${target_lab_id}) && ${lab_id} != ${target_lab_id} ]]; then
            continue
        fi
        if safe_pushd "${lab_id}"; then
            for dir in */; do
                if [[ ! (-z ${target_prob_id}) && $dir != "${target_prob_id}/" ]]; then
                    #echo "skip ${dir}"
                    continue
                fi

                if safe_pushd $dir; then
                    prob_id=${dir%/}
                    for file in *.c; do
                        if [[ $file != "Main.c" && $file != *_correct.c ]]; then
                            prog_id=${file%.c}
                            if [[ ! (-z ${target_prog_id}) && ${prog_id} != ${target_prog_id} ]]; then
                                # echo "skip ${prog_id}"
                                continue
                            fi
                            if [[ ${skip_done} == 0 ]]; then
                                simple_prog_id=$(echo ${prog_id} | sed "s/_buggy//g")
                                if grep "${simple_prog_id}" ${result_file} | \
                                    grep "${prob_id}" | grep -q "${lab_id}"; then
                                    # echo "Skip ${lab_id} ${prob_id} ${prog_id}"
                                    continue
                                fi
                            fi
                            # echo "${lab_id} ${prob_id} ${prog_id}"
                            safe_rm "-rf" ${prog_id}
                            mkdir -p ${prog_id}
                            cp ${prog_id}.c ${prog_id}
                            handle ${lab_id} ${prob_id} ${prog_id} \
                                ${skip_ag} ${skip_gp_ww} ${skip_gp_ga}
                        fi
                    done
                    popd &> /dev/null
                fi
            done
            popd &> /dev/null
        fi
    done
    popd &> /dev/null
fi
