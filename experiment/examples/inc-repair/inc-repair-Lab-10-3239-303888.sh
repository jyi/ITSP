#!/bin/bash

rm -f result-inc-repair
cp result-inc-repair.template result-inc-repair

export submissions_root="/ITSP-experiments/dataset-inc-repair"
export test_dir=${submissions_root}/test
export prog_name="prog"
export test_gp_rep_file="test-gp-rep"
export test_gp_rep_slot="TEST_GP_REP"
export pr_fixed_test_case_file="fixed-test-case"
export main_result_file=$(pwd)/result-inc-repair
export partial_result_file=$(pwd)/result-partial
export base_result=$(pwd)/result-base
export wrapper_name="wrapper-repair"
export repair_src_name="repair"
export ref_dir="ref"
export repair_makefile="Makefile.repair"
export ag_session_prefix="ag-session"
export ww_session_prefix="ww-session"
export ga_session_prefix="ga-session"
export pr_session_prefix="pr-session"
export pr_refine_session_prefix="pr-session-refine"
export pr_control_session_prefix="pr-session-control"
export succeed_file="succeed"
export fail_file="failure"
export result_file_name="result"
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

export ga_edit_degree=2

function safe_pushd () {
    local target=$1

    if pushd $target &> /dev/null; then
        return 0
    else
        echo "[* Error *] Failed to push to $target"
        return 1
    fi
}
export -f safe_pushd

function safe_rm () {
    local flag=$1
    local target=$2

    if [[ $target =~ ^[a-zA-Z0-9][a-zA-Z0-9/\_\-]*$ ]]; then
        return $(rm $flag $target)
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

function create_revision_log_for_refine () {
    local prob_id=$1
    local prog_id=$2
    local inst=$3
    local basic_test_script=$4
    local fixed_case=$5

    cases=($(grep -P "^\tp" ${basic_test_script} | cut -d"|" -f1 | cut -d"<" -f2 | sed -e "s/.txt//g" | sed -e "s?test/in.${prob_id}.??g" | tr -d "\n"))
    cases[${#cases[@]}]=${fixed_case}

    rm -f ${pr_revision_file} &> /dev/null
    touch ${pr_revision_file} &> /dev/null
    write_to_file ${pr_revision_file} "-"
    write_to_file ${pr_revision_file} "-"
    write_to_file ${pr_revision_file} "Diff Cases: Tot ${#cases[@]}"
    negs_line="${cases[@]}"
    write_to_file ${pr_revision_file} "${negs_line}"

    write_to_file ${pr_revision_file} "Positive Cases: Tot 0"
}
export -f create_revision_log_for_refine

function create_revision_log_for_controlflow_fix () {
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
export -f create_revision_log_for_controlflow_fix

function create_revision_log_for_dataflow_fix () {
    local prob_id=$1
    local prog_id=$2
    local inst=$3
    local basic_test_script=$4

    negs=($(grep -P "^\tn" ${basic_test_script} | cut -d"|" -f1 | cut -d"<" -f2 | sed -e "s/.txt//g" | sed -e "s?test/in.${prob_id}.??g" | tr -d "\n"))

    rm -f ${pr_revision_file} &> /dev/null
    touch ${pr_revision_file} &> /dev/null
    write_to_file ${pr_revision_file} "-"
    write_to_file ${pr_revision_file} "-"
    write_to_file ${pr_revision_file} "Diff Cases: Tot ${#negs[@]}"
    negs_line="${negs[@]}"
    write_to_file ${pr_revision_file} "${negs_line}"

    write_to_file ${pr_revision_file} "Positive Cases: Tot 0"
}
export -f create_revision_log_for_dataflow_fix

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

function create_gp_Makefile() {
    local prog_id=$1
    rm -f Makefile
    touch Makefile
    write_to_file Makefile "all:"
    write_to_file Makefile "$(printf "\tgcc -std=c99 -o %s %s" "${prog_name}" "${prog_id}.c -lm")"
}
export -f create_gp_Makefile

function create_repair_Makefile() {
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

function create_gp_ww_config () {
    local prog_id=$1
    local inst=$2
    local gp_ww_test_script=$3
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
    write_to_file ${gp_config_file} "--fault-scheme uniform"
    write_to_file ${gp_config_file} "--add-guard"
    write_to_file ${gp_config_file} "$(printf "%slabel-repair" "--")"
    write_to_file ${gp_config_file} "$(printf "%spos-tests ${pos_test}" "--")"
    write_to_file ${gp_config_file} "$(printf "%sneg-tests ${neg_test}" "--")"
    write_to_file ${gp_config_file} "--test-script ./${gp_ww_test_script}"

    echo ${gp_config_file}
}
export -f create_gp_ww_config

function create_gp_ga_config () {
    local prog_id=$1
    local inst=$2
    local gp_ga_test_script=$3
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
    write_to_file ${gp_config_file} "--fault-scheme uniform"
    write_to_file ${gp_config_file} "--add-guard"
    write_to_file ${gp_config_file} "$(printf "%slabel-repair" "--")"
    write_to_file ${gp_config_file} "$(printf "%spos-tests ${pos_test}" "--")"
    write_to_file ${gp_config_file} "$(printf "%sneg-tests ${neg_test}" "--")"
    write_to_file ${gp_config_file} "$(printf "%sseed 560680701" "--")"
    write_to_file ${gp_config_file} "$(printf "%sminimization" "--")"
    write_to_file ${gp_config_file} "$(printf "%sswapp 0.0" "--")"
    write_to_file ${gp_config_file} "$(printf "%sappp 0.5" "--")"
    write_to_file ${gp_config_file} "$(printf "%sdelp 0.5" "--")"
    write_to_file ${gp_config_file} "$(printf "%scrossp 0.0" "--")"
    write_to_file ${gp_config_file} "$(printf "%spopsize 20" "--")"
    write_to_file ${gp_config_file} "$(printf "%sgenerations 10" "--")"
    write_to_file ${gp_config_file} "$(printf "%sset-edit-degree ${ga_edit_degree}" "--")"
    write_to_file ${gp_config_file} "$(printf "%ssingle-fitness" "--")"
    write_to_file ${gp_config_file} "$(printf "%sallow-coverage-fail" "--")"
    write_to_file ${gp_config_file} "--test-script ./${gp_ga_test_script}"

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
export -f prepare_tests

function is_positive_test () {
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
export -f is_positive_test

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
export -f create_basic_test_script

function create_gp_ww_test_script() {
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
    write_to_file ${script} "rm -f ${test_gp_rep_file}"
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
    write_to_file ${script} "\tn1)"
    for idx in $(seq 0 $((${#negs[@]} - 1))); do
        line=$(echo ${negs[$idx]})
        neg_test_id=$(echo $line | cut -d")" -f1)
        neg_test_cmd=$(echo $line | cut -d")" -f2 | cut -d"&" -f1)
        write_to_file ${script} "\tif [[ -z \$(timeout 1 ${neg_test_cmd}) ]]; then"
        write_to_file ${script} "\t\techo \"${neg_test_id}\" > ${test_gp_rep_file}"
        write_to_file ${script} "\t\texit 0"
        write_to_file ${script} "\tfi"
    done
    write_to_file ${script} "\t;;"

    write_to_file ${script} "esac"
    write_to_file ${script} "exit 1"
    chmod +x ${script}
}
export -f create_gp_ww_test_script

function create_gp_ga_test_script() {
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
        neg_test_id=$(echo $line | cut -d")" -f1)
        neg_test_cmd=$(echo $line | cut -d")" -f2 | cut -d"&" -f1)
        write_to_file ${script} "$(printf "\t${neg_test_id}) timeout 1 ${neg_test_cmd} ;;")"
    done

    # for single-fitness
    write_to_file ${script} "\ts)"
    # negative test
    for idx in $(seq 0 $((${#negs[@]} - 1))); do
        line=$(echo ${negs[$idx]})
        neg_test_id=$(echo $line | cut -d")" -f1)
        neg_ids[$idx]=${neg_test_id}
        input_file=$(echo $line | cut -d")" -f2 | cut -d"|" -f1 | cut -d"<" -f2)
        exp_out_file=$(echo $line | cut -d")" -f2 | cut -d"|" -f2 | cut -d" " -f4)
        write_to_file ${script} "\trm -f out.txt"
        write_to_file ${script} "\ttimeout 1s \$1 < ${input_file} > out.txt | similarity out.txt ${exp_out_file} > \$5"
        write_to_file ${script} "\tf_${neg_test_id}=\$(head -n 1 \$5)"
        write_to_file ${script} "\tif [[ \$(echo \"\${f_${neg_test_id}} == 1.0\" | bc -l) == 1 ]]; then"
        write_to_file ${script} "\t\techo \"${neg_test_id}\" > ${test_gp_rep_file}"
        write_to_file ${script} "\t\texit 0"
        write_to_file ${script} "\tfi"
    done
    write_to_file ${script} ""

    # positive tests
    for idx in $(seq 0 $((${#poses[@]} - 1))); do
        line=$(echo ${poses[$idx]})
        pos_test_id=$(echo $line | cut -d")" -f1)
        pos_ids[$idx]=${pos_test_id}
        input_file=$(echo $line | cut -d")" -f2 | cut -d"|" -f1 | cut -d"<" -f2)
        exp_out_file=$(echo $line | cut -d")" -f2 | cut -d"|" -f2 | cut -d" " -f4)
        write_to_file ${script} "\trm -f out.txt"
        write_to_file ${script} "\ttimeout 1s \$1 < ${input_file} > out.txt | similarity out.txt ${exp_out_file} > \$5"
        write_to_file ${script} "\tf_${pos_test_id}=\$(head -n 1 \$5)"
    done
    write_to_file ${script} ""

    # average
    sum_exp=""
    for idx in $(seq 0 $((${#pos_ids[@]} - 1))); do
        if [[ $idx == 0 ]]; then
            sum_exp="\${f_${pos_ids[$idx]}}"
        else
            sum_exp="${sum_exp} + \${f_${pos_ids[$idx]}}"
        fi
    done

    total=$((${#pos_ids[@]}+1))
    for idx in $(seq 0 $((${#neg_ids[@]} - 1))); do
        write_to_file ${script} "\tf_${neg_ids[$idx]}_avg=\$(echo \"(\${f_${neg_ids[$idx]}} + ${sum_exp})/${total}\" | bc -l)"
    done
    write_to_file ${script} ""

    fit_avgs_array_exp="fit_avgs=("
    for idx in $(seq 0 $((${#neg_ids[@]} - 1))); do
        if [[ $idx == 0 ]]; then
            fit_avgs_array_exp="${fit_avgs_array_exp}\${f_${neg_ids[$idx]}_avg}"
        else
            fit_avgs_array_exp="${fit_avgs_array_exp} \${f_${neg_ids[$idx]}_avg}"
        fi
    done
    fit_avgs_array_exp="${fit_avgs_array_exp})"
    write_to_file ${script} "\t${fit_avgs_array_exp}"
    write_to_file ${script} "\tmax_fit=\$(printf \"%f\\\\n\" \"\${fit_avgs[@]}\" | sort -rn | head -1)"
    write_to_file ${script} "\techo \${max_fit} > \$5"

    write_to_file ${script} "\t;;"
    write_to_file ${script} "esac"
    write_to_file ${script} "exit 1"
    chmod +x ${script}
}
export -f create_gp_ga_test_script

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
        line=$(echo $line | sed -e "s?\&\& exit 0?\& pid=\$! \&\& echo \$pid \>\> \${pid_log_file} \&\& wait \$pid \&\& exit 0?g")
        write_to_file ${script} "$(printf "\t$line")"
    done
    for idx in $(seq 0 $((${#negs[@]} - 1))); do
        line=$(echo ${negs[$idx]} | sed -e "s?\$1?\${ANGELIX_RUN:-timeout 1} ./${wrapper_name}?g")
        line=$(echo $line | sed -e "s?test/?../../test/?g")
        line=$(echo $line | sed -e "s?| diff -ZB??g")
        line=$(echo $line | sed -e "s?- \&\&?\&\&?g")
        line=$(echo $line | sed -e "s?\&\& exit 0?\& pid=\$! \&\& echo \$pid \>\> \${pid_log_file} \&\& wait \$pid \&\& exit 0?g")
        write_to_file ${script} "$(printf "\t$line")"
    done

    write_to_file ${script} "esac"
    write_to_file ${script} "exit 1"
    chmod +x ${script}
}
export -f create_ag_test_script

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
export -f create_clean_script

function run_gp() {
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
    local prob_id=$3
    local prophet_log=$4
    local basic_test_script=$5
    local pr_params=$6

    eval $__pr_time=0

    cat <<EOF >> ${pr_config_file}
${pr_run_conf_file} -r ${pr_workdir} -consider-all -feature-para ${PROPHET_FEATURE_PARA} ${pr_params}
EOF

    rm -rf workdir
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
        eval $__found_repair=0
        echo "[pr] found a repair"
        cp __fixed*.c repair.c
        if [[ -s ${pr_fixed_test_case_file} ]]; then
            fixed_case=$(cat ${pr_fixed_test_case_file})
            fixed_neg_test=$(cat ${basic_test_script} | grep in.${prob_id}.${fixed_case}.txt | cut -d")" -f1 | tr -d [:blank:])
            echo $fixed_neg_test > ${test_gp_rep_file}
        fi
    else
        eval $__found_repair=1
        echo "[pr] failed to find a repair"
    fi
}
export -f run_prophet

function run_angelix () {
    local __guard_ok=$1
    local __tests_ok=$2
    local __found_repair=$3
    local __ag_time=$4
    local found_df_repair=$5
    local ag_test_script=$6
    local ag_config_file=$7
    local gp_repair_dir=$8
    local angelix_log=$9

    eval $__guard_ok=1
    eval $__tests_ok=1
    eval $__found_repair=1
    eval $__ag_time=0

    if [[ ${found_df_repair} == 0 ]]; then
        # collect lines
        IFS_BAK=${IFS}
        IFS="
"
        lines=($(grep -n "if (1 != 0)\|if (1 == 0)" ${gp_repair_dir}/${repair_src_name}.c | cut -d':' -f1))
        IFS=${IFS_BAK}
        if [[ -z $lines ]]; then
            eval $__guard_ok=1 && return
        else
            eval $__guard_ok=0
        fi
    else
        eval $__guard_ok=0
    fi

    # collect positive tests
    pos_tests=($(grep -P "^\tp" ${ag_test_script} | cut -d$'\t' -f2 | cut -d')' -f1))
    if [[ -z ${pos_tests} ]]; then
        eval $__tests_ok=1 # && return
    else
        eval $__tests_ok=0
    fi

    # prepare configuration file
    rm -f ${ag_config_file}
    touch ${ag_config_file}
    if [[ ${found_df_repair} == 0 ]]; then
        # repair only control-flow bugs
        cat <<EOF >> ${ag_config_file}
${gp_repair_dir} ${repair_src_name}.c ${ag_test_script} ${pos_tests[@]} ${test_gp_rep_slot} \
        --golden ref --lines ${lines[@]} --group-size ${#lines[@]} \
        --synthesis-levels alternatives mixed-conditional --use-nsynth \
        --synthesis-func-params --synthesis-global-vars --synthesis-used-vars \
        --init-uninit-vars \
        --klee-ignore-errors --ignore-infer-errors \
        --klee-max-forks ${klee_max_forks} --klee-max-depth 200 --max-angelic-paths 10 \
        --klee-timeout ${klee_timeout} --synthesis-timeout ${synthesis_timeout} \
        --test-timeout ${test_timeout} --timeout ${tool_timeout} --verbose
EOF
    else
        cat <<EOF >> ${ag_config_file}
${gp_repair_dir} ${repair_src_name}.c ${ag_test_script} ${pos_tests[@]} ${test_gp_rep_slot} \
        --golden ref --defect if-conditions loop-conditions \
        --synthesis-levels alternatives mixed-conditional --use-nsynth \
        --synthesis-func-params --synthesis-global-vars --synthesis-used-vars \
        --init-uninit-vars \
        --klee-ignore-errors --ignore-infer-errors \
        --klee-max-forks ${klee_max_forks} --klee-max-depth 200 --max-angelic-paths 10 \
        --klee-timeout ${klee_timeout} --synthesis-timeout ${synthesis_timeout} \
        --test-timeout ${test_timeout} --timeout ${tool_timeout} --verbose
EOF
    fi

    if ! [[ -e ${ag_config_file} ]]; then
        echo "[AG] ${ag_config_file} does not exist" && eval $__found_repair=1 && return
    fi

    if ! [[ -e ${test_gp_rep_file} ]]; then
        echo "[AG] ${test_gp_rep_file} does not exist" && eval $__found_repair=1 && return
    fi

    rm -f *.patch
    rm -f ${angelix_log}
    local angelix_timeout=$((tool_timeout+10))
    ulimit -n 4000 # increase the maximum number of open file descriptors
    START_TIME=$SECONDS
    timeout ${angelix_timeout} angelix `test_gp_rep=$(cat ${test_gp_rep_file}); cat ${ag_config_file} | sed "s/${test_gp_rep_slot}/${test_gp_rep}/"` &> ${angelix_log}
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

function run_angelix_parallel_internal () {
    local gp_repair_dir=$1
    local ag_test_script=$2
    local ag_config_file=$3
    local inst=$4
    local repair_mode=$5
    local neg=$6

    local session_dir="${ag_session_prefix}-$neg-${inst}"
    local log_file="angelix.log"
    local time_log_file="time.log"

    rm -rf ${session_dir}
    mkdir -p ${session_dir}
    cp -r ${gp_repair_dir} ${session_dir}
    cp -r ref ${session_dir}
    cp -r test ${session_dir}
    cp ${ag_test_script} ${session_dir}

    # collect positive/negative tests
    pos_tests=($(grep -P "^\tp" ${ag_test_script} | cut -d$'\t' -f2 | cut -d')' -f1))
    neg_tests=($(grep -P "^\tn" ${ag_test_script} | cut -d$'\t' -f2 | cut -d')' -f1))

    echo "repair_mode: ${repair_mode}"
    if safe_pushd "${session_dir}"; then
        case ${repair_mode} in
            control)
                cat <<EOF >> ${ag_config_file}
${gp_repair_dir} ${repair_src_name}.c ${ag_test_script} ${pos_tests[@]} ${neg} \
        --golden ref --defect if-conditions loop-conditions \
        --synthesis-levels alternatives extended-logic extended-inequalities mixed-conditional --use-nsynth \
        --synthesis-func-params --synthesis-global-vars --synthesis-used-vars \
        --init-uninit-vars \
        --klee-ignore-errors --ignore-infer-errors \
        --klee-max-forks ${klee_max_forks} --klee-max-depth 200 --max-angelic-paths 10 \
        --klee-timeout ${klee_timeout} --synthesis-timeout ${synthesis_timeout} \
        --test-timeout ${test_timeout} --timeout ${tool_timeout} --verbose
EOF
                ;;
            data)
                cat <<EOF >> ${ag_config_file}
${gp_repair_dir} ${repair_src_name}.c ${ag_test_script} ${neg} \
        --golden ref --defect assignments \
        --synthesis-levels alternatives integer-constants variables basic-arithmetic extended-arithmetic conditional-arithmetic --use-nsynth \
        --synthesis-func-params --synthesis-global-vars --synthesis-used-vars \
        --init-uninit-vars \
        --klee-ignore-errors --ignore-infer-errors \
        --klee-max-forks ${klee_max_forks} --klee-max-depth 200 --max-angelic-paths 10 \
        --klee-timeout ${klee_timeout} --synthesis-timeout ${synthesis_timeout} \
        --test-timeout ${test_timeout} --timeout ${tool_timeout} --verbose
EOF
                ;;
            *)
                echo "unrecognized repair_mode: ${repair_mode}"
                ;;
        esac

        rm -f *.patch
        rm -f ${log_file}
        local angelix_timeout=$((tool_timeout+10))
        ulimit -n 4000 # increase the maximum number of open file descriptors
        START_TIME=$SECONDS
        timeout ${angelix_timeout} angelix `cat ${ag_config_file}` &> ${log_file} & pid=$!
        echo $pid > ${angelix_pid_log_file}
        wait $pid
        ag_time=$(($SECONDS - $START_TIME))
        echo ${ag_time} > ${time_log_file}

        if [ -s *.patch ]; then
            echo "$neg: patch succeeds"
            return 0
        else
            echo "$neg: patch fails"
            return 1
        fi
        popd &> /dev/null
    else
        echo "Failed to push ${session_dir} at $(pwd)"
        return 1
    fi
}
export -f run_angelix_parallel_internal

function run_angelix_parallel () {
    local __guard_ok=$1
    local __tests_ok=$2
    local __found_repair=$3
    local __ag_time=$4
    local ag_test_script=$5
    local ag_config_file=$6
    local gp_repair_dir=$7
    local angelix_log=$8
    local inst=${9}
    local __repaired_test=${10}
    local repair_mode=${11}

    eval $__guard_ok=1
    eval $__tests_ok=1
    eval $__found_repair=1
    eval $__ag_time=0

    # collect positive/negative tests
    pos_tests=($(grep -P "^\tp" ${ag_test_script} | cut -d$'\t' -f2 | cut -d')' -f1))
    neg_tests=($(grep -P "^\tn" ${ag_test_script} | cut -d$'\t' -f2 | cut -d')' -f1))
    if [[ -z ${pos_tests} ]]; then
        eval $__tests_ok=1 # && return
    else
        eval $__tests_ok=0
    fi

    parallel --halt now,success=1 run_angelix_parallel_internal \
        ${gp_repair_dir} ${ag_test_script} ${ag_config_file} ${inst} ${repair_mode} \
        ::: ${neg_tests[@]} &> ${angelix_log}
    repaired_test=$(grep "patch succeeds" ${angelix_log} | cut -d":" -f1)
    if [ ! -z $repaired_test ]; then
        eval $__found_repair=0
        eval $__repaired_test=${repaired_test}
        eval $__ag_time=$(cat "${ag_session_prefix}-${repaired_test}-${inst}/time.log")
    else
        eval $__found_repair=1
    fi
}
export -f run_angelix_parallel

function create_extract_source_awk () {
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

function create_remove_dummy_var_awk() {
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
    local found_df_repair=$1
    local angelix_log=$2

    if [[ ${found_df_repair} == 1 ]]; then
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

function repair_controlflow_in_parallel () {
    local prob_id=$1
    local prog_id=$2
    local inst=$3
    local basic_test_script=$4
    local gp_repair_dir=$5
    local ag_config_file=$6
    local cf_result_file=$7
    local repair_mode=${8}

    case ${repair_mode} in
        pr)
            found_pr_repair=1
            if [[ ${skip_pr_cf_fix} != 0 ]]; then
                local session_dir="${pr_control_session_prefix}-${inst}"
                rm -rf ${session_dir} && mkdir -p ${session_dir}
                cp ${basic_test_script} ${session_dir}
                cp -r test ${session_dir}

                local src_dir="src"
                if safe_pushd "${session_dir}"; then
                    rm -rf ${src_dir} && mkdir -p ${src_dir}
                    cp ../${prog_id}.c ${src_dir}
                    if safe_pushd "${src_dir}"; then
                        create_pr_Makefile ${prog_id}
                        popd &> /dev/null
                    fi
                    create_pr_test_script ${prob_id}
                    create_revision_log_for_controlflow_fix ${prob_id} ${prog_id} ${inst} \
                        ${basic_test_script}
                    create_pr_run_conf ${src_dir}

                    log_file="prophet-control-${inst}.log"
                    run_prophet found_pr_repair pr_time ${prob_id} ${log_file} \
                        ${basic_test_script} \
                        "-cond-ext -not-fix-data-flow -partial"

                    if [[ ${found_pr_repair} == 0 ]]; then
                        repair_ok=0
                    fi

                    repaired_test=$(cat ${test_gp_rep_file})
                    popd &> /dev/null
                fi

                #######################
                # write result
                #######################
                write_to_file ${cf_result_file} "pr-repaired-test=${repaired_test}"
                write_to_file ${cf_result_file} "found_pr_repair_control=${found_pr_repair}"

                if [[ ${found_pr_repair} == 0 ]]; then
                    echo "[pr] succeeded to fix a control flow error"
                    touch ${succeed_file}-control-${inst}
                    return 0
                else
                    echo "[pr] failed to fix a control flow error"
                    touch ${fail_file}-control-${inst}
                    return 1
                fi
            else
                echo "[pr] control-flow fix skipped"
                return 1
            fi
            ;;
        ag)
            found_ag_repair=1
            if [[ ${skip_ag_cf_fix} != 0 ]]; then
                repair_file="${prog_id}-${inst}.c"
                if ! [[ -e ${repair_file} ]]; then
                    echo "${repair_file} doest no exist"
                else
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
                        create_wrapper_file "../../Main.c"
                        popd &> /dev/null
                    fi

                    guard_ok=1
                    tests_ok=1
                    log_file="angelix_control-${inst}.log"
                    repaired_test=""
                    run_angelix_parallel guard_ok tests_ok found_ag_repair ag_start_time \
                        ${ag_test_script} ${ag_config_file} \
                        ${gp_repair_dir} ${log_file} ${inst} repaired_test \
                        "control"
                fi

                #######################
                # write result
                #######################
                write_to_file ${cf_result_file} "ag-repaired-test=${repaired_test}"
                write_to_file ${cf_result_file} "found_ag_repair_control=${found_ag_repair}"

                if [[ ${found_ag_repair} == 0 ]]; then
                    echo "[ag] succeeded to fix a control flow error"
                    touch ${succeed_file}-control-${inst}
                    return 0
                else
                    echo "[ag] failed to fix a control flow error"
                    touch ${fail_file}-control-${inst}
                    return 1
                fi
            else
                echo "[ag] control-flow fix skipped"
                return 1
            fi
            ;;
    esac
}
export -f repair_controlflow_in_parallel

function repair_dataflow_in_parallel () {
    local prob_id=$1
    local prog_id=$2
    local inst=$3
    local basic_test_script=$4
    local gp_ww_test_script=$5
    local gp_ga_test_script=$6
    local num_of_pos=$7
    local num_of_neg=$8
    local gp_repair_dir=$9
    local ag_config_file=${10}
    local repair_mode=${11}

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
                    create_revision_log_for_dataflow_fix ${prob_id} ${prog_id} ${inst} \
                        ${basic_test_script}
                    create_pr_run_conf ${src_dir}
                    found_pr_repair_data=1
                    log_file="prophet-${inst}.log"
                    run_prophet found_pr_repair_data pr_time ${prob_id} ${log_file} \
                        ${basic_test_script} \
                        "-replace-ext -not-fix-control-flow -partial"
                    popd &> /dev/null
                fi

                if [[ $found_pr_repair_data == 0 ]]; then
                    echo "[pr] repair succeeded"
                    touch ${session_dir}/${succeed_file}
                    return 0
                else
                    echo "[pr] repair failed"
                    touch ${session_dir}/${fail_file}
                    return 1
                fi
            else
                echo "[pr] skipped"
                return 1
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
                        echo "repair file ${repair_file} does not exist"
                    else
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
                        log_file="angelix_data-${inst}.log"
                        repaired_test=""
                        run_angelix_parallel guard_ok tests_ok found_ag_repair ag_start_time \
                            ${ag_test_script} ${ag_config_file} \
                            ${gp_repair_dir} ${log_file} ${inst} repaired_test "data"

                        if [[ ${found_ag_repair} == 0 ]]; then
                            echo "ag succeeded"
                            touch ${succeed_file}
                        else
                            echo "ag failed"
                            touch ${fail_file}
                        fi
                    fi
                    popd &> /dev/null
                fi

                if [[ ${found_ag_repair} == 0 ]]; then
                    echo "[ag] repair succeeded"
                    return 0
                else
                    echo "[ag] repair failed"
                    return 1
                fi
            else
                echo "[ag] skipped"
                return 1
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
                    # run GenProg to obtain repair.sanity.c
                    gp_config_file=$(create_gp_ww_config ${prog_id} ${inst} ${gp_ww_test_script} 0 0)
                    run_gp ${gp_config_file} "gp-empty-${inst}.log" tmp1 tmp2 &> /dev/null

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

                    create_gp_ww_test_script ${prog_id} ${basic_test_script} ${gp_ww_test_script}
                    gp_config_file=$(create_gp_ww_config ${prog_id} ${inst} ${gp_ww_test_script} 0 1)

                    log_file="gp-ww-${inst}.log"
                    gp_ok=0
                    found_gp_repair=1
                    run_gp ${gp_config_file} ${log_file} found_gp_repair gp_ww_time
                    if [[ $found_gp_repair == 1 ]]; then
                        diagnose_gp_repair_failure ${log_file} gp_ok fail_reason
                        echo "fail_reason: ${fail_reason}"
                        touch ${fail_file}
                        write_to_file ${fail_file} "fail_reason=${fail_reason}"
                    else
                        touch ${succeed_file}
                    fi

                    popd &> /dev/null
                fi

                if [[ $found_gp_repair == 0 ]]; then
                    echo "[ww] repair succeeded"
                    return 0
                else
                    echo "[ww] repair failed"
                    return 1
                fi
            else
                echo "[ww] skipped"
                return 1
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
                    # run GenProg to obtain repair.sanity.c
                    gp_config_file=$(create_gp_ww_config ${prog_id} ${inst} ${gp_ww_test_script} 0 0)
                    run_gp ${gp_config_file} "gp-empty-${inst}.log" tmp1 tmp2 &> /dev/null

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

                    create_gp_ga_test_script ${prog_id} ${basic_test_script} ${gp_ga_test_script}

                    gp_config_file=$(create_gp_ga_config \
                        ${prog_id} ${inst} ${gp_ga_test_script} ${num_of_pos} ${num_of_neg})

                    log_file="gp-ga-${inst}.log"
                    gp_ok=0
                    found_gp_repair=1
                    run_gp ${gp_config_file} ${log_file} found_gp_repair gp_ga_time
                    if [[ $found_gp_repair == 1 ]]; then
                        diagnose_gp_repair_failure ${log_file} gp_ok fail_reason
                        echo "[ga] fail_reason: ${fail_reason}"
                        touch ${fail_file}
                    else
                        touch ${succeed_file}
                    fi
                    popd &> /dev/null
                fi

                if [[ $found_gp_repair == 0 ]]; then
                    echo "[ga] repair succeeded"
                    return 0
                else
                    echo "[ga] repair failed"
                    return 1
                fi
            else
                echo "[ga] skipped"
                return 1
            fi
            ;;
    esac
}
export -f repair_dataflow_in_parallel

function repair_in_parallel () {
    local prob_id=$1
    local prog_id=$2
    local inst=$3
    local basic_test_script=$4
    local gp_ww_test_script=$5
    local gp_ga_test_script=$6
    local ag_test_script=$7
    local ag_config_file=${8}
    local gp_repair_dir=${9}
    local cf_result_file=${10}
    local df_result_file=${11}
    local num_of_pos=${12}
    local num_of_neg=${13}
    local df_fix_only=${14}
    local repair_mode=${15}

    #########################################
    # collect positive and negative tests
    #########################################
    IFS_BAK=${IFS}
    IFS="
"
    local poses=($(grep -P "^\tp" ${basic_test_script}))
    local negs=($(grep -P "^\tn" ${basic_test_script}))
    IFS=${IFS_BAK}

    case ${repair_mode} in
        control)
            local parallel_log_file="repair_controlflow_in_parallel-${inst}.log"
            parallel --halt now,success=1 repair_controlflow_in_parallel \
                ${prob_id} ${prog_id} ${inst} \
                ${basic_test_script} ${gp_repair_dir} ${ag_config_file} \
                ${cf_result_file} \
                ::: "ag" "pr" &> ${parallel_log_file}
            ;;
        data)
            repair_ok=1
            found_gp_repair_ww=""
            found_gp_repair_ga=""
            found_ag_repair_data=""
            found_pr_repair_data=""
            found_ag_repair_refine=""

            local parallel_log_file="repair_dataflow_in_parallel-${inst}.log"
            parallel --halt now,success=1 repair_dataflow_in_parallel \
                ${prob_id} ${prog_id} ${inst} ${basic_test_script} \
                ${gp_ww_test_script} ${gp_ga_test_script} \
                ${num_of_pos} ${num_of_neg} ${gp_repair_dir} ${ag_config_file} \
                ::: "ww" "ga" "ag" "pr" &> ${parallel_log_file}

            rm -f repair.c
            if [ -e "${ag_session_prefix}-${inst}/${succeed_file}" ]; then
                echo "[ag] repair succeeded"
                found_ag_repair_data=0
                if safe_pushd "${ag_session_prefix}-${inst}"; then
                    [ -e repair.c ] && cp repair.c ..
                    [ -e ${test_gp_rep_file} ] && cp ${test_gp_rep_file} ..
                    popd &> /dev/null
                fi
            elif [ -e "${ww_session_prefix}-${inst}/${succeed_file}" ]; then
                echo "[ww] repair succeeded"
                found_gp_repair_ww=0
                if safe_pushd "${ww_session_prefix}-${inst}"; then
                    [ -e repair.c ] && cp repair.c ..
                    [ -e ${test_gp_rep_file} ] && cp ${test_gp_rep_file} ..
                    popd &> /dev/null
                fi
            elif [ -e "${ga_session_prefix}-${inst}/${succeed_file}" ]; then
                echo "[ga] repair succeeded"
                found_gp_repair_ga=0
                if safe_pushd "${ga_session_prefix}-${inst}"; then
                    [ -e repair.c ] && cp repair.c ..
                    [ -e ${test_gp_rep_file} ] && cp ${test_gp_rep_file} ..
                    popd &> /dev/null
                fi
            elif [ -e "${pr_session_prefix}-${inst}/${succeed_file}" ]; then
                echo "[pr] repair succeeded"
                found_pr_repair_data=0
                if safe_pushd "${pr_session_prefix}-${inst}"; then
                    [ -e repair.c ] && cp repair.c ..
                    [ -e ${test_gp_rep_file} ] && cp ${test_gp_rep_file} ..
                    popd &> /dev/null
                fi
            else
                found_gp_repair_ww=1
                found_gp_repair_ga=1
                found_ag_repair_data=1
                found_pr_repair_data=1
            fi

            found_df_repair=1
            if [[ ${found_gp_repair_ww} == 0 || ${found_gp_repair_ga} == 0 || ${found_ag_repair_data} == 0 || ${found_pr_repair_data} == 0 ]]; then
                found_df_repair=0
            fi

            if [[ ${df_fix_only} == 0 ]]; then
                [[ ${found_df_repair} == 0 ]] && repair_ok=0
            else
                ############################################
                # prepare gp_repair_dir
                ############################################
                if [[ ${found_df_repair} == 0 && -e repair.c ]]; then
                    cp repair.c repair-${inst}.c
                    repair_file="../repair-${inst}.c"
                    safe_rm "-rf" ${gp_repair_dir} && mkdir -p ${gp_repair_dir}

                    if safe_pushd "${gp_repair_dir}"; then
                        create_ag_Makefile "-std=c99"
                        create_wrapper_file ${repair_file}
                        popd &> /dev/null
                    fi
                fi

                ############################################
                # Check if all positive tests already pass
                ############################################
                if [[ -e repair.c ]]; then
                    pass_all_pos=0
                    rm -f "repair"
                    create_repair_Makefile && make -f ${repair_makefile} &> /dev/null
                    for idx in $(seq 0 $((${#poses[@]} - 1))); do
                        line=$(echo ${poses[$idx]})
                        test_id=$(echo $line | cut -d")" -f1)
                        test_cmd=$(echo $line | cut -d")" -f2 | cut -d"&" -f1)
                        in_file=$(echo $test_cmd | cut -d"|" -f1 | cut -d"<" -f2)
                        local out_file=$(echo ${in_file} | sed -e "s/in/out/g")
                        is_pos=$(is_positive_test "./repair" ${in_file} ${out_file})
                        if [[ ${is_pos} != 0 ]]; then
                            pass_all_pos=1
                            break
                        fi
                    done
                    if [[ ${pass_all_pos} == 0 ]]; then
                        echo "all current positive tests pass"
                        repair_ok=0
                    else
                        echo "repair should be refined"
                    fi
                fi

                #########################################
                # Refine with Angelix
                #########################################
                if [[ ${skip_ag_refine} != 0 ]]; then
                    if [[ ${found_df_repair} == 0 && ${pass_all_pos} != 0 ]]; then
                        found_ag_repair_refine=1

                        safe_rm "-rf" ${ref_dir} && mkdir -p ${ref_dir}
                        create_ag_test_script ${basic_test_script} ${ag_test_script}

                        if safe_pushd "${ref_dir}"; then
                            create_ag_Makefile "-std=c99"
                            create_wrapper_file "../../Main.c"
                            popd &> /dev/null
                        fi

                        guard_ok=1
                        tests_ok=1
                        log_file="angelix_refine-${inst}.log"
                        run_angelix guard_ok tests_ok found_ag_repair_refine ag_refine_time \
                            ${found_df_repair} ${ag_test_script} ${ag_config_file} \
                            ${gp_repair_dir} ${log_file}
                        echo "found_ag_repair_refine: ${found_ag_repair_refine}"

                        if [[ ${found_ag_repair_refine} == 0 ]]; then
                            echo "succeeded to refine a repair with Angelix"
                            repair_ok=0
                        else
                            echo "failed to refine a repair with Angelix"
                        fi

                        fail_reason=""
                        if [[ ${found_ag_repair_refine} == 1 ]]; then
                            fail_reason=$(diagnose_ag_repair_failure ${found_df_repair} \
                                ${log_file})
                            echo "[ag] refinement failure reason: ${fail_reason}"
                        fi
                    fi
                else
                    echo "Skip to reinfe with Angelix"
                fi

                #########################################
                # Refine with Prophet
                #########################################
                if [[ ${skip_pr_refine} != 0 ]]; then
                    if [[ ${found_df_repair} == 0 && ${pass_all_pos} != 0 && ${found_ag_repair_refine} == 1 ]]; then
                        echo "Try to refine a repair with Prophet"
                        local session_dir="${pr_refine_session_prefix}-${inst}"
                        rm -rf ${session_dir} && mkdir -p ${session_dir}
                        cp ${basic_test_script} ${session_dir}
                        cp -r test ${session_dir}
                        cp ${test_gp_rep_file} ${session_dir}

                        local src_dir="src"
                        if safe_pushd "${session_dir}"; then
                            rm -rf ${src_dir} && mkdir -p ${src_dir}
                            cp ../repair.c ${src_dir}/${prog_id}.c
                            if safe_pushd "${src_dir}"; then
                                create_pr_Makefile ${prog_id}
                                popd &> /dev/null
                            fi
                            create_pr_test_script ${prob_id}

                            local fixed_test_id=$(cat ${test_gp_rep_file})
                            local fixed_case=$(grep ${fixed_test_id} ${basic_test_script} \
                                | cut -d")" -f2 | cut -d"|" -f1 | cut -d"<" -f2 \
                                | cut -d"/" -f2 | cut -d"." -f3)
                            create_revision_log_for_refine ${prob_id} ${prog_id} ${inst} \
                                ${basic_test_script} ${fixed_case}
                            create_pr_run_conf ${src_dir}

                            ############################
                            # lines to refine
                            ############################
                            IFS_BAK=${IFS}
                            IFS="
"
                            lines=($(grep -n "if (1 != 0)\|if (1 == 0)" \
                                ${src_dir}/${prog_id}.c | cut -d':' -f1))
                            IFS=${IFS_BAK}
                            for idx in $(seq 0 $((${#lines[@]} - 1))); do
                                local new_line=$((${lines[$idx]}+1))
                                lines[$idx]=$new_line
                            done

                            found_pr_repair_refine=1
                            if [[ ${#lines[@]} != 0 ]]; then
                                log_file="prophet-refine-${inst}.log"
                                run_prophet found_pr_repair_refine pr_time ${prob_id} ${log_file} \
                                    ${basic_test_script} \
                                    "-cond-ext -not-fix-data-flow -skip-verify --lines ${lines[@]}"
                            else
                                echo "A guard to refine is NOT found"
                            fi

                            if [[ ${found_pr_repair_refine} == 0 ]]; then
                                echo "succeeded to refine a repair with Prophet"
                                repair_ok=0
                            else
                                echo "failed to refine a repair with Prophet"
                            fi
                            popd &> /dev/null
                        fi
                    fi
                else
                    echo "Skip to reinfe with Prophet"
                fi
            fi

            #######################
            # write result
            #######################
            write_to_file ${df_result_file} "found_df_repair=${found_df_repair}"
            write_to_file ${df_result_file} "found_gp_repair_ww=${found_gp_repair_ww}"
            write_to_file ${df_result_file} "found_gp_repair_ga=${found_gp_repair_ga}"
            write_to_file ${df_result_file} "found_pr_repair_data=${found_pr_repair_data}"
            write_to_file ${df_result_file} "found_ag_repair_data=${found_ag_repair_data}"
            write_to_file ${df_result_file} "found_ag_repair_refine=${found_ag_repair_refine}"
            write_to_file ${df_result_file} "found_pr_repair_refine=${found_pr_repair_refine}"
            write_to_file ${df_result_file} "fail_reason=${fail_reason}"

            if [[ ${repair_ok} == 0 ]]; then
                echo "succeeded to fix a data flow error"
                touch ${succeed_file}-data-${inst}
                return 0
            else
                echo "failed to fix a data flow error"
                touch ${fail_file}-data-${inst}
                write_to_file ${fail_file}-data-${inst} "fail_reason=${fail_reason}"
                return 1
            fi
            ;;
        *)
            echo "unrecognized repair_mode: ${repair_mode}"
            return 1
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
    local first_it_only=$7
    local df_fix_only=$8

    local inst=0
    local num_of_pos=-1
    local num_of_neg=-1

    if safe_pushd "${prog_id}"; then
        cp ${prog_id}.c ${prog_id}.c.org
        popd &> /dev/null
    fi

    while true; do
        local repair_done=1
        local prev_num_of_pos=${num_of_pos}
        handle_instance $1 $2 $3 $4 $5 $6 $inst ${df_fix_only} repair_done num_of_pos num_of_neg
        echo "repair done at ${inst}: ${repair_done}"
        if [[ $first_it_only == 0 || $num_of_neg == 0 || $repair_done == 1 || ${num_of_pos} -le ${prev_num_of_pos} ]]; then
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
    local df_fix_only=$8
    local __repair_done=$9
    local __num_of_pos=${10}
    local __num_of_neg=${11}

    ag_start_time=0
    gp_ww_time=0
    gp_ga_time=0
    ag_refine_time=0
    time_parallel=""

    local repair_ok=1
    eval ${__repair_done}=1

    local cf_result_file=${result_file_name}-control-${inst}
    rm -f ${cf_result_file}
    touch ${cf_result_file}


    local df_result_file=${result_file_name}-data-${inst}
    rm -f ${df_result_file}
    touch ${df_result_file}

    rm -rf /tmp/*

    if safe_pushd "${prog_id}"; then
        echo "[*] handle ${lab_id}-${prob_id}-${prog_id}-${inst}"

        gp_ww_test_script="test-gp-ww-${inst}.sh"
        gp_ga_test_script="test-gp-ga-${inst}.sh"
        ag_test_script="test-angelix-${inst}.sh"
        ag_config_file="ag-${inst}.config"

        gp_repair_dir="gp-repaired-${inst}"
        ag_repair_dir="ag-repaired-${inst}"

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
                guard_ok=""
                tests_ok=""
                fail_reason="Failed to compile"
                break
            else
                create_clean_script
                prepare_tests ${prob_id}
                basic_test_script="test-${inst}.sh"
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

                local parallel_log_file="repair_in_parallel-${inst}.log"
                START_TIME=$SECONDS
                parallel --halt now,success=1 repair_in_parallel \
                    ${prob_id} ${prog_id} ${inst} ${basic_test_script} \
                    ${gp_ww_test_script} ${gp_ga_test_script} ${ag_test_script} \
                    ${ag_config_file} ${gp_repair_dir} \
                    ${cf_result_file} ${df_result_file} \
                    ${num_of_pos} ${num_of_neg} ${df_fix_only} \
                    ::: "control" "data" &> ${parallel_log_file}
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

                #############################
                # Delete unnecessary files
                #############################
                for file in $(find ./ -name *.smt2); do
                    rm -f $file
                done

                for file in $(find ./ -name *.ktest); do
                    rm -f $file
                done

                for file in $(find ./ -name *.ll); do
                    rm -f $file
                done

                for file in $(find ./ -name *.bc); do
                    rm -f $file
                done

                found_gp_repair_ww=""
                found_gp_repair_ga=""
                found_ag_repair_data=""
                found_pr_repair_data=""
                found_ag_repair_refine=""
                found_ag_repair_control=""
                found_pr_repair_control=""
                repaired_test=""
                found_pr_repair_refine=""
                if [ -e "${df_result_file}" ]; then
                    found_gp_repair_ww=$(grep "found_gp_repair_ww" \
                        ${df_result_file} | cut -d"=" -f2)
                    found_gp_repair_ga=$(grep "found_gp_repair_ga" \
                        ${df_result_file} | cut -d"=" -f2)
                    found_pr_repair_data=$(grep "found_pr_repair_data" \
                        ${df_result_file} | cut -d"=" -f2)
                    found_ag_repair_data=$(grep "found_ag_repair_data" \
                        ${df_result_file} | cut -d"=" -f2)
                    found_ag_repair_refine=$(grep "found_ag_repair_refine" \
                        ${df_result_file} | cut -d"=" -f2)
                    found_pr_repair_refine=$(grep "found_pr_repair_refine" \
                        ${df_result_file} | cut -d"=" -f2)
                fi

                if [ -e "${cf_result_file}" ]; then
                    found_ag_repair_control=$(grep "found_ag_repair_control" \
                        ${cf_result_file} | cut -d"=" -f2)
                    found_pr_repair_control=$(grep "found_pr_repair_control" \
                        ${cf_result_file} | cut -d"=" -f2)
                    if [[ ${found_ag_repair_control} == 0 ]]; then
                        repaired_test=$(grep "ag-repaired-test" \
                            ${cf_result_file} | cut -d"=" -f2)
                    elif [[ ${found_pr_repair_control} == 0 ]]; then
                        repaired_test=$(grep "pr-repaired-test" \
                            ${cf_result_file} | cut -d"=" -f2)
                    fi
                fi

                if [ -e "${succeed_file}-control-${inst}" ]; then
                    echo "control-flow error fixed"
                    repair_ok=0
                elif [ -e "${succeed_file}-data-${inst}" ]; then
                    echo "data-flow error fixed"
                    repair_ok=0
                fi
            fi
        done

        echo "repair_ok: ${repair_ok}"
        echo "found_ag_repair_control: ${found_ag_repair_control}"
        echo "found_gp_repair_ww: ${found_gp_repair_ww}"
        echo "found_gp_repair_ga: ${found_gp_repair_ga}"
        echo "found_pr_repair_data: ${found_pr_repair_data}"
        echo "found_pr_repair_control: ${found_pr_repair_control}"
        echo "found_ag_repair_data: ${found_ag_repair_data}"
        echo "found_ag_repair_refine: ${found_ag_repair_refine}"
        echo "found_pr_repair_refine: ${found_pr_repair_refine}"

        if [[ $repair_ok == 0 ]]; then
            eval ${__repair_done}=0
        fi

        ###########################
        # prepare the next source
        ###########################
        if [[ $first_it_only == 1 && $repair_ok == 0 ]]; then
            echo "prepare the next source ..."
            fail_reason=""

            if [[ ${#negs[@]} -gt 0 ]]; then
                if [[ -n ${found_ag_repair_refine} && ${found_ag_repair_refine} == 0 ]]; then
                    cp -r .angelix/validation/ ${ag_repair_dir}
                elif [[ -n ${found_ag_repair_control} && ${found_ag_repair_control} == 0 ]]; then
                    echo "copy ${ag_session_prefix}-${repaired_test}-${inst}/.angelix/validation/"
                    cp -r ${ag_session_prefix}-${repaired_test}-${inst}/.angelix/validation/ \
                        ${ag_repair_dir}
                elif [[ -n ${found_pr_repair_refine} && ${found_pr_repair_refine} == 0 ]]; then
                    echo "copy ${pr_refine_session_prefix}-${inst}"
                    cp -r ${pr_refine_session_prefix}-${inst} ${ag_repair_dir}
                elif [[ -n ${found_pr_repair_control} && ${found_pr_repair_control} == 0 ]]; then
                    cp -r ${pr_control_session_prefix}-${inst} ${ag_repair_dir}
                else
                    cp -r ${gp_repair_dir} ${ag_repair_dir}
                fi

                if safe_pushd "${ag_repair_dir}"; then
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
        write_to_file ${csv_file} "${lab_id}\t${prob_id}\t${simple_prog_id}\t${inst}\t${num_of_pos}\t${num_of_neg}\t${found_gp_repair_ww}\t${found_gp_repair_ga}\t${found_pr_repair_data}\t${found_ag_repair_data}\t${found_ag_repair_control}\t${found_pr_repair_control}\t${found_ag_repair_refine}\t${found_pr_repair_refine}\t${repair_ok}\t${time_parallel}"
        popd &> /dev/null
    fi
}

function look_up_entry () {
    local -n __entries=$1
    local entry=$2
    local __index=$3

    for idx in $(seq 0 $((${#__entries[@]} - 1))); do
        if [[ ${__entries[$idx]} == "$entry" ]]; then
            eval $__index=$idx
            break
        fi
    done
}

function transfer_result_from_main () {
    local lab_id=$1
    local prob_id=$2
    local simple_prog_id=$3

    IFS_BAK=${IFS}
    IFS="
"
    lines=($(grep -P "${lab_id}\t${prob_id}\t${simple_prog_id}" ${main_result_file}))
    IFS=${IFS_BAK}

    for idx in $(seq 0 $((${#lines[@]} - 1))); do
        line=$(echo "${lines[$idx]}" | sed -e "s/ /\t/g")
        write_to_file ${csv_file} "$line"
    done
}
export -f transfer_result_from_main

function transfer_result_from_base () {
    local lab_id=$1
    local prob_id=$2
    local simple_prog_id=$3

    IFS_BAK=${IFS}
    IFS="	"
    head=($(grep -P "lab\tprob\tprog\tinst" ${base_result}))
    IFS=${IFS_BAK}
    look_up_entry head "lab" lab_idx
    look_up_entry head "prob" prob_idx
    look_up_entry head "prog" prog_idx
    look_up_entry head "inst" inst_idx
    look_up_entry head "pos" pos_idx
    look_up_entry head "neg" neg_idx
    look_up_entry head "rep_ok" rep_ok_idx
    look_up_entry head "time" time_idx

    result_inst0=$(grep -P "${lab_id}\t${prob_id}\t${simple_prog_id}\t0" ${base_result} \
        | sed 's/\t/:/g')
    result_inst1=$(grep -P "${lab_id}\t${prob_id}\t${simple_prog_id}\t1" ${base_result} \
        | sed 's/\t/:/g')

    row0=$(echo $result_inst0 | cut -d":" -f$((lab_idx+1)))
    row0+="\t"
    row0+=$(echo $result_inst0 | cut -d":" -f$((prob_idx+1)))
    row0+="\t"
    row0+=$(echo $result_inst0 | cut -d":" -f$((prog_idx+1)))
    row0+="\t"
    row0+=$(echo $result_inst0 | cut -d":" -f$((inst_idx+1)))
    row0+="\t"
    row0+=$(echo $result_inst0 | cut -d":" -f$((pos_idx+1)))
    row0+="\t"
    row0+=$(echo $result_inst0 | cut -d":" -f$((neg_idx+1)))
    row0+="\t\t\t\t\t\t\t\t\t"
    row0+=$(echo $result_inst0 | cut -d":" -f$((rep_ok_idx+1)))
    row0+="\t"
    row0+=$(echo $result_inst0 | cut -d":" -f$((time_idx+1)))

    row1=$(echo $result_inst1 | cut -d":" -f$((lab_idx+1)))
    row1+="\t"
    row1+=$(echo $result_inst1 | cut -d":" -f$((prob_idx+1)))
    row1+="\t"
    row1+=$(echo $result_inst1 | cut -d":" -f$((prog_idx+1)))
    row1+="\t"
    row1+=$(echo $result_inst1 | cut -d":" -f$((inst_idx+1)))
    row1+="\t"
    row1+=$(echo $result_inst1 | cut -d":" -f$((pos_idx+1)))
    row1+="\t"
    row1+=$(echo $result_inst1 | cut -d":" -f$((neg_idx+1)))
    row1+="\t\t\t\t\t\t\t\t\t"
    row1+=$(echo $result_inst1 | cut -d":" -f$((rep_ok_idx+1)))
    row1+="\t"
    row1+=$(echo $result_inst1 | cut -d":" -f$((time_idx+1)))

    write_to_file ${csv_file} "$row0"
    write_to_file ${csv_file} "$row1"
}
export -f transfer_result_from_base

##########################################################################################

export target_lab_id="Lab-10"
export target_prob_id="3239"
export target_prog_id="303888_buggy"

# default: 1
export skip_ag_cf_fix=1
export skip_pr_cf_fix=1
export skip_ag=1
export skip_pr=1
export skip_gp_ww=1
export skip_gp_ga=1
export skip_ag_refine=1
export skip_pr_refine=1

# default: 1
export df_fix_only=1
export first_it_only=1
export skip_handle=1
export only_handle_when_complete_fix_exists=1

# default: 0
export skip_done=0
export skip_complete_fix=0

if [[ ${only_handle_when_complete_fix_exists} == 0 ]]; then
    csv_file=${partial_result_file}
    skip_complete_fix=1
else
    csv_file=${main_result_file}
fi

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
                            simple_prog_id=$(echo ${prog_id} | sed "s/_buggy//g")
                            if [[ ! (-z ${target_prog_id}) && ${prog_id} != ${target_prog_id} ]]; then
                                #echo "skip ${prog_id}"
                                continue
                            fi
                            if [[ ${skip_done} == 0 ]]; then
                                if grep "${simple_prog_id}" ${csv_file} | \
                                    grep "${prob_id}" | grep -q "${lab_id}"; then
                                    #echo "Skip ${lab_id} ${prob_id} ${prog_id}"
                                    continue
                                fi
                            fi

                            ########################################
                            # Check whehter a complete fix exists
                            ########################################
                            IFS_BAK=${IFS}
                            IFS="	"
                            entries=($(grep -P "^lab" ${base_result}))
                            IFS=${IFS_BAK}

                            rep_ok_idx=1000 # bogus value
                            look_up_entry entries "rep_ok" rep_ok_idx
                            rep_ok=$(grep -P "${lab_id}\t${prob_id}\t${simple_prog_id}\t0" \
                                ${base_result} | cut -d$'\t' -f$((rep_ok_idx+1)))

                            neg_idx=1000 # bogus value
                            look_up_entry entries "neg" neg_idx
                            neg=$(grep -P "${lab_id}\t${prob_id}\t${simple_prog_id}\t0" \
                                ${base_result} | cut -d$'\t' -f$((neg_idx+1)))

                            if [[ $rep_ok == 0 && $neg == 0 ]]; then
                                complete_fix_exist=0
                            else
                                complete_fix_exist=1
                            fi

                            if [[ $complete_fix_exist == 0 ]]; then
                                # a complete fix exists
                                if [[ ${skip_complete_fix} == 0 ]]; then
                                    echo "Skip ${lab_id} ${prob_id} ${prog_id} (already fixed)"
                                    transfer_result_from_base ${lab_id} ${prob_id} ${simple_prog_id}
                                    continue
                                fi
                            fi

                            if [[ $skip_handle != 0 ]]; then
                                if [[ ${only_handle_when_complete_fix_exists} == 0 ]]; then
                                    if [[ $complete_fix_exist == 0 ]]; then
                                        # echo "${lab_id} ${prob_id} ${prog_id}"
                                        safe_rm "-rf" ${prog_id}
                                        mkdir -p ${prog_id}
                                        cp ${prog_id}.c ${prog_id}
                                        handle ${lab_id} ${prob_id} ${prog_id} \
                                            ${skip_ag} ${skip_gp_ww} ${skip_gp_ga} \
                                            ${first_it_only} ${df_fix_only}
                                    else
                                        echo "Skip ${lab_id} ${prob_id} ${prog_id} (no complete fix exists)"
                                        transfer_result_from_main ${lab_id} ${prob_id} ${simple_prog_id}
                                    fi
                                else
                                    # echo "${lab_id} ${prob_id} ${prog_id}"
                                    safe_rm "-rf" ${prog_id}
                                    mkdir -p ${prog_id}
                                    cp ${prog_id}.c ${prog_id}
                                    handle ${lab_id} ${prob_id} ${prog_id} \
                                        ${skip_ag} ${skip_gp_ww} ${skip_gp_ga} \
                                        ${first_it_only} ${df_fix_only}
                                fi
                            fi
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
