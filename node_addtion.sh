###############################################################################
# Dt: 07/20/2017
# Sript_Name : New Node Addtion
# Description : This script ensures installation of CM_Agents
#               Starting of CM agents, and Role Addition to the new nodes      
# Flow :
#	1)Installs CM agents
#	3)Edits /etc/cloudera-scm-agent/config.ini file and starts cm Agents
#	4)Add Nodes to the Given cluster & Add Roles on them
#usage :
#./node_addition.sh 
################################################################################
source ./shflags

# Define globals
ROTATE_LOG=${ROTATE_LOG:-0}
RUNTIME_LOG=./runtime.log
RUNTIME_OUT=./runtime.out
UMASK=`umask`
HTTP_PROTOCOL=""
TRUE=$FLAGS_TRUE
FALSE=$FLAGS_FALSE

###################################################################
# Begin config section
JAVA_HOME="/usr/java/latest"
host=`hostname`
VERSION="5.11"
CM_SERVER=""
CM_USERNAME=""
CM_PASSWORD=""
CLUSTER="ClusterName"
SCRIPT_PATH="/path to /python node addition script/"
CERTS_PATH="/opt/cloudera/security/pki"

###################################################################


cm_agent_install(){

    echo "===========================CM Agent Installation==========================================="
    echo "==========================================================================================="
    eval "yum install cloudera-manager-agent-${VERSION} -y"
    eval "sed -i.$(date +%Y%m%d%H%M%S).bak 's,server_host=.*,server_host='\"${CM_SERVER}\"',;s,use_tls=.,use_tls=1,;s,.*verify_cert_file=.*,verify_cert_file='\"${CERTS_PATH}\"'/ca-certs.pem,;s,.*client_key_file=.*,client_key_file='\"${CERTS_PATH}\"'/server.key,;s,.*client_cert_file=.*,client_cert_file='\"${CERTS_PATH}\"'/server.pem,' /etc/cloudera-scm-agent/config.ini"

}

cm_agent_start() {
    echo "===========================START CM Agent=================================================="
    echo "==========================================================================================="
    eval "service cloudera-scm-agent start"
}

cm_node_role_addition(){ 
    echo "===========================Adding Node Roles to the Cluster================================"
    echo "===========================================================================================" 
    eval "python ${SCRIPT_PATH}/cm_add_new_host.py ${CM_SERVER} ${CM_USERNAME} ${CM_PASSWORD} ${CLUSTER} ${host} "
}



cm_agent_install $VERSION
cm_agent_start
cm_node_role_addition $CM_SERVER $CM_USERNAME $CM_PASSWORD $CLUSTER $host