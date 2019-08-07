#!/bin/bash

#set -x

# Node List
NODE_LIST="10.0.2.51"


# Date/Time Veriables

LOG_DATE="date +%Y-%m-%d"
LOG_TIME="date +%H-%M-%S"

CDATE=`date "+%Y-%m-%d"`
CTIME=`date "+%H-%M-%S"`

# Shell Env
SHELL_NAME="deploy.sh"
SHELL_DIR="/root"
SHELL_LOG="${SHELL_DIR}/${SHELL_NAME}.log"
LOCK_FILE="/tmp/deploy.lock"



#Code Env
PRO_NAME="web-demo"
CODE_DIR="/deploy/code/web-demo"
CONFIG_DIR="/deploy/config/web-demo"
TMP_DIR="/deploy/tmp"
TAR_DIR="/deploy/tar"

for GET_DIR in ${SHELL_DIR} ${CODE_DIR} ${CONFIG_DIR} ${TMP_DIR} ${TAR_DIR}
  do
    [ ! -f ${GET_DIR} ] && mkdir ${GET_DIR} -p
  done

usage(){
    echo $"Usage: $0  { deploy | rollback [ list  | version ]}"
}

shell_lock(){
    touch ${LOCK_FILE}
}

shell_unlock(){
    rm -f ${LOCK_FILE}
}

writelog(){
    LOGINFO=$1
    echo "`${LOG_DATE}` `${LOG_TIME}`  : ${SHELL_NAME}   : ${LOGINFO}" >> ${SHELL_LOG}

}


code_get(){
    writelog 'code_get';
    cd ${CODE_DIR} && git pull;
    /bin/cp  ${CODE_DIR} ${TMP_DIR}/ -r;
    API_VERL=`git show | grep commit | awk '{print $2}'`;
    API_VER=`echo ${API_VERL:0:6}`
}

code_build(){
    echo code_build;

}

code_config(){
    echo code_config
    /bin/cp ${CONFIG_DIR} ${TMP_DIR} -r;
    PKG_NAME=${PRO_NAME}_${API_VER}_${CDATE}_${CTIME};
    cd ${TMP_DIR} && mv ${PRO_NAME} ${PKG_NAME};


}

code_tar(){
    writelog "code_tar";
    cd ${TMP_DIR} && /bin/tar -czf ${PKG_NAME}.tgz ${PKG_NAME};
    writelog ${PKG_NAME}.tgz;


}

code_scp(){
    writelog  "code_scp";
    for node in ${NODE_LIST}
    do
      scp ${TMP_DIR}/${PKG_NAME}.tgz ${node}:/data/webroot
    done
    
}

cluster_node_remove(){
    writelog "cluster_node_remove"; 

}

code_deploy(){
    echo code_deploy;
    for node in $NODE_LIST 
      do 
        ssh $node "cd /data/webroot && tar xf ${PKG_NAME}.tgz";
        ssh $node "rm -rf /webroot/web-demo && ln -s /data/webroot/${PKG_NAME} /webroot/web-demo";
      done 
}

config_diff(){
    echo config_diff;
    

}

code_test(){
    echo code_test 

}

cluster_node_in(){
    echo cluster_node_in 

}


rollback_fun(){
    for node in $NODE_LIST 
      do 
         ssh $node "rm -rf /webroot/web-demo && ln -s /data/webroot/$1 /webroot/web-demo";
      done 
}


rollback(){
    [ -z $1 ] && shell_unlock &&  echo "空" && exit 2;
    case $1 in 
      list)
            ls -l /data/webroot/*.tgz;
            ;;
         *)
            rollback_fun $1;
    esac 

}

main(){
    [  -f ${LOCK_FILE} ] && echo "Deploy is running" && exit 1;

    DEPLOY_METHOD=$1
    ROLLBACK_VER=$2
    case $DEPLOY_METHOD in
      deploy)
        shell_lock;
        code_get;
        code_build;
        code_config;
        code_tar;
        code_scp;
        cluster_node_remove;
        code_deploy;
#        config_diff;
        code_test;
        cluster_node_in;
        shell_unlock;
        ;;
      rollback)
        shell_lock;
        rollback ${ROLLBACK_VER};
        shell_unlock;
        ;;
      *)
        usage;
    esac
}
main $1 $2
