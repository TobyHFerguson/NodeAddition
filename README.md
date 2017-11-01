# NodeAddition
Automated Node Addition: Automates addition of a new node/list of new nodes with help of CM API to cluster. This eliminates the manual steps using UI to add the node. Once the prechecks are validated, user can triger the script to add the node to the cluster.


Steps to run: 

Note: This scripts should be used after the following host prechecks are configured and one is ready to add the new host to cluster
  Prerequisite Checks : 
    OS Validations: Ensure following OS level validations
    vm.swappiness=1
    Firewall (ip tables) is disabled
    SE Linux is disabled
    Transparent Huge Pages are disabled
    IPv6 is disabled
    NTPD is synchronized and running
    Forward and Reverse DNS Lookup is enabled
    Disk Check

  Security checks
    Kereberos Checks: 
      Validate openldap-clients and krb5workstation, krb5-libs are installed
      A copy of krb5.conf is copied to the new node to /etc/krb5.conf
      Correct version of jdk and jce are installed

    TLS [Assuming TLS is already enabled for Cloudera Manager Server and Agents (CM TLS level 3) ]
      Node should have valid certificates : The Server certificates, java keystore, CA certs should be placed in the correct locations.(mostly /opt/cloudera/security/<ca-certs/pki/jks/x509> )
      
   
 1. After the prechecks, configure the config section parameters in node_addition.sh
    JAVA_HOME="/usr/java/latest"
    host=`hostname`
    VERSION="5.11"
    CM_SERVER=""
    CM_USERNAME=""
    CM_PASSWORD=""
    CLUSTER=""
    SCRIPT_PATH="/path to python cm_new_host_addition.py script/"
    CERTS_PATH="/opt/cloudera/security/pki"
  
 2. ./node_addition.sh
 
