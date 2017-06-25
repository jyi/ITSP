FROM jayyi/angelix:0.0

MAINTAINER Jooyong Yi <jooyong.m.lee@gmail.com>

######################
# Dependencies
######################
RUN apt-get -y update
RUN apt-get -y install git make wget unzip m4 gcc curl indent software-properties-common maven
## RUN apt-add-repository -y ppa:webupd8team/java && apt-get -y update
## RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
## RUN apt-get -y install oracle-java8-installer
## RUN unset JAVA_TOOL_OPTIONS


#################
# Install ocaml
#################
RUN wget https://raw.github.com/ocaml/opam/master/shell/opam_installer.sh -O - | sh -s /usr/local/bin
RUN opam init -y --comp=3.12.1
RUN eval `opam config env`
RUN opam install -y ocamlfind
WORKDIR /root/.opam/3.12.1/lib/ocaml
RUN ln -s libcamlstr.a libstr.a

####################
# Install parallel
####################
WORKDIR /
RUN wget https://ftp.gnu.org/gnu/parallel/parallel-20161122.tar.bz2
RUN bzip2 -dc parallel-20161122.tar.bz2 | tar xvf -
WORKDIR /parallel-20161122
RUN ./configure && make && make install
RUN rm -f parallel-20161122.tar.bz2 && rm -rf parallel-20161122

######################
# Download
######################
WORKDIR /
RUN git clone https://github.com/jyi/ITSP.git

######################
# Environment
######################
ENV ITSP_DIR /ITSP
ENV ITSP_EXP_DIR /ITSP-experiments
ENV CIL="${ITSP_DIR}/genprog-source-v3.0/cil-1.3.7"
ENV PATH="/root/.opam/3.12.1/bin:${PATH}:${CIL}/bin:${ITSP_DIR}/genprog-source-v3.0/src:${ITSP_DIR}/prophet-gpl/src:${ITSP_DIR}/prophet-gpl/tools"
ENV SIMILARITY_JAR=${ITSP_DIR}/java-string-similarity/target/java-string-similarity-0.20-SNAPSHOT.jar
ENV PROPHET_FEATURE_PARA=${ITSP_DIR}/prophet-gpl/crawler/para-all.out
ENV PROPHET_TOOLS_DIR=${ITSP_DIR}/prophet-gpl/tools
ENV PS1="\n\w\n\W > "
ENV PROMPT_COMMAND=


######################
# Install GenProg
######################
WORKDIR ${ITSP_DIR}/genprog-source-v3.0
RUN tar zxvf cil-1.3.7.tar.gz
WORKDIR ${ITSP_DIR}/genprog-source-v3.0/cil-1.3.7
RUN ./configure && make && make cillib
WORKDIR ${ITSP_DIR}/genprog-source-v3.0/src
RUN make

####################################
# Install java-string-similarity
####################################
WORKDIR ${ITSP_DIR}/java-string-similarity
RUN mvn package

######################
# Install Prophet
######################
WORKDIR /
RUN wget http://releases.llvm.org/3.6.1/clang+llvm-3.6.1-x86_64-linux-gnu-ubuntu-14.04.tar.xz
RUN tar xf clang+llvm-3.6.1-x86_64-linux-gnu-ubuntu-14.04.tar.xz
RUN rm -f clang+llvm-3.6.1-x86_64-linux-gnu-ubuntu-14.04.tar.xz

WORKDIR /clang+llvm-3.6.1-x86_64-linux-gnu
RUN cp bin/* /usr/local/bin/
RUN cp -r include/* /usr/local/include/
RUN cp -r lib/* /usr/local/lib/

WORKDIR ${ITSP_DIR}/prophet-gpl
RUN apt-get -y install autotools-dev automake libtool zlib1g-dev
RUN apt-add-repository -y ppa:pmiller-opensource/ppa && apt-get -y update
RUN apt-get install -y libexplain-dev
RUN aclocal && autoconf && autoreconf --install && automake
RUN ./configure
RUN make clean && make

######################
# Clean up
######################
WORKDIR /
RUN rm -rf clang+llvm-3.6.1-x86_64-linux-gnu
RUN rm -rf parallel-20161122
RUN rm -f parallel-20161122.tar.bz2

######################
# Experiment Setup
######################
WORKDIR /
RUN mkdir -p ${ITSP_EXP_DIR}

RUN echo "source /angelix/activate" >> /root/.bashrc
RUN echo "source ${ITSP_DIR}/activate.sh" >> /root/.bashrc
RUN echo "export JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8" >> /root/.bashrc

WORKDIR ${ITSP_DIR}
RUN cp -r ${ITSP_DIR}/dataset ${ITSP_EXP_DIR}/dataset-base
RUN cp -r ${ITSP_DIR}/dataset ${ITSP_EXP_DIR}/dataset-inc-repair

WORKDIR /

