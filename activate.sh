unset JAVA_TOOL_OPTIONS

export PROJECT_ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export GENPROG_ROOT=${PROJECT_ROOT}/genprog-source-v3.0
export PROPHET_ROOT=${PROJECT_ROOT}/prophet-gpl
export SIMILARITY_ROOT=${PROJECT_ROOT}/java-string-similarity
export CGUM_ROOT=${PROJECT_ROOT}/cgum
export GUMTREE_ROOT=${PROJECT_ROOT}/gumtree
export GUMTREE_DIST_ROOT=${GUMTREE_ROOT}/dist/build/distributions/gumtree

export SIMILARITY_JAR=${SIMILARITY_ROOT}/target/java-string-similarity-0.20-SNAPSHOT.jar

export PROPHET_FEATURE_PARA=${PROPHET_ROOT}/crawler/para-all.out
export PROPHET_TOOLS_DIR=${PROPHET_ROOT}/tools

case ":$PATH:" in
    *":$GENPROG_ROOT/src:"*) :;;
    *) export PATH=$GENPROG_ROOT/src:$PATH
esac

case ":$PATH:" in
    *":$PROPHET_ROOT/src:"*) :;;
    *) export PATH=$PROPHET_ROOT/src:$PATH
esac

case ":$PATH:" in
    *":$PROPHET_ROOT/tools:"*) :;;
    *) export PATH=$PROPHET_ROOT/tools:$PATH
esac

case ":$PATH:" in
    *":$PROJECT_ROOT/tools:"*) :;;
    *) export PATH=$PROJECT_ROOT/tools:$PATH
esac
