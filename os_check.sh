#/bin/bash

LOG_FILE=/tmp/`hostname`.log
UPDATE='true'
## Clear file if exists
function clear_log {
	rm -f $LOG_FILE
}

function log_msg {
	echo "$1 " | tee -a $LOG_FILE
}

## VM Swappiness
function vmswappiness {
	if [ $(cat /proc/sys/vm/swappiness) -eq 1 ]
	then
		log_msg "PASS: vm.swappiness"
	else
		log_msg "FAIL: vm.swappiness on host `hostname`"
		if $UPDATE
		then
			 sysctl -w vm.swappiness=1
             echo 1 > /proc/sys/vm/swappiness
             if [[ `grep '/proc/sys/vm/swappiness' "/etc/rc.local" | wc -l` -ne 0 ]]
             then
             echo "echo 1 > /proc/sys/vm/swappiness" >> /etc/rc.local
             fi
			log_msg "PASS: vm.swappiness is SET to 1"
		fi
	fi	
}

function thp {
	cat /sys/kernel/mm/transparent_hugepage/enabled | grep "\[never\]" > /dev/null
	if [ $(echo $?) -eq 0 ]
	then
		log_msg "PASS: Transparent hugepages"
	else
		log_msg "FAIL: Transparent hugepages"
		if [ $UPDATE ]
		then
			log_msg "Disabling transparent hugepages..."
			echo never > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
    		 if [[ `grep never "/sys/kernel/mm/transparent_hugepage/khugepaged/defrag" | wc -l` -ne 0 ]]
             then
             echo "echo never > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag" >> /etc/rc.local"
             fi
            log_msg "PASS: Transparent hugepages disabled."
		fi
	fi
}

function ntpd {
	systemctl status ntpd | grep "Active" | grep "running" > /dev/null
	if [ $(echo $?) -eq 0 ]
	then
		log_msg "PASS: NTPD service is running"
	else
		log_msg "FAIL: NTPD service not running"
		if [ $UPDATE ]
		then
			log_msg "Starting service..."
			 systemctl stop ntpd.service
             ntpdate -s 10.133.31.2
             systemctl start ntpd.service
			log_msg "PASS: NTPD service is running started"
		fi
	fi

	log_msg "`systemctl list-unit-files | grep 'ntpd\.' | awk '{ if ($2=="enabled") print "PASS: ntpd "$2; else print "FAIL: ntpd "$2}'`"
}

function selinux {
	/usr/sbin/sestatus | grep "SELinux status:" | grep "disabled" > /dev/null
	if [ $(echo $?) -eq 0 ]
	then
		log_msg "PASS: SELinux is disabled"
	else
		log_msg "FAIL: SELinux is not disabled"
		if [ $UPDATE ]
		then
			 setenforce 0
			 sed -i.old s/SELINUX=enforcing/SELINUX=disabled/ /etc/selinux/config
			if [ $(echo $?) -eq 0 ]
			then
				log_msg "SELinux is disabled temperaroly, reboot required "
			fi
			log_msg "PASS: selinux is disabled."
		fi
	fi
}

function mail {
	/usr/bin/which mailx > /dev/null
	if [ $(echo $?) -eq 0 ]
	then
        	log_msg "PASS: mailx is confiured"
	else
		log_msg "FAIL: mailx is not configured."
	fi
}

function nscdservice {
	systemctl status nscd | grep "Active" | grep "running" > /dev/null
	if [ $(echo $?) -eq 0 ]
	then
		log_msg "PASS: NSCD is running"
	else
		log_msg "FAIL: NSCD service not instaled/configured."
		if [ $UPDATE ]
		then
			 systemctl start nscd
			log_msg "PASS: NSCD service is configured/installed"
		fi
	fi
}

function ipv6status {
	if [ lsmod | grep ipv6 -ne 0 ]
	then
		log_msg "FAIL: ipv6 is enabled"
	else
		log_msg "PASS: ipv6 is disabled"
	fi
}


function firewall {
	systemctl status firewalld | grep "Active" | grep "inactive" > /dev/null
	if [ $(echo $?) -eq 0 ]
	then
		log_msg "PASS: firewall is disabled"
	else
		log_msg "FAIL: firewall is active"
		if [ $UPDATE ]
		then
			log_msg "Disabling firewall"
			 systemctl disable firewalld
			 systemctl stop firewalld
		fi
	fi
}

function hostsfile {
	if [ $(cat /etc/hosts | grep -v "`hostname`\|127.0.0.1\|localhost\|^$\|^\s*\#" | wc -l) -le 0 ]
	then
        	log_msg "PASS: Hosts file is clean"
	else
        	log_msg "FAIL: Unexpected records are present."
	fi
}

function fstabnoatime {
	data=$(cat /etc/fstab | grep "\/data" | wc -l)
	noatime=$(cat /etc/fstab | grep "\/data" | grep noatime | wc -l)

	if [ $data -eq $noatime ]
	then
		log_msg "PASS: All the drives mounted with noatime setting"
	else
		log_msg "FAIL: Some drives are not mounted with noatime setting"
	fi
}

function entropycheck {
	if [ `cat /proc/sys/kernel/random/entropy_avail` -le 2000 ]
	then
		log_msg "PASS: Entropy value is < 2000"
	else
		log_msg "FAIL: Entropy value is > 2000"
	fi
}

function diskblocksize {
	partitions=$(grep /data /etc/fstab | cut -d" " -f1)
	for i in $partitions
	do
		blocksz=$( blockdev --getbsz $i)
		if [ $blocksz -eq 4096 ]
		then
			log_msg "PASS: disk $i has block size of $blocksz"
		else
			log_msg "FAIL: Block size on $i is set to $blocksz"
		fi
	done
}

function functionalUsers {
log_msg "`cat /etc/passwd | grep cloudera-scm | awk -F":" '{print $1,$5}' | awk '{ if( $1=="cloudera-scm"&&$2=="Hadoop") print "PASS: cloudera-scm functional account correctly established."; else print "FAIL: cloudera-scm functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep accumulo | awk -F":" '{print $1,$5}' | awk '{ if( $1=="accumulo"&&$2=="Hadoop") print "PASS: accumulo functional account correctly established."; else print "FAIL: accumulo functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep flume | awk -F":" '{print $1,$5}' | awk '{ if( $1=="flume"&&$2=="Hadoop") print "PASS: flume functional account correctly established."; else print "FAIL: flume functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep hbase | awk -F":" '{print $1,$5}' | awk '{ if( $1=="hbase"&&$2=="Hadoop") print "PASS: hbase functional account correctly established."; else print "FAIL: hbase functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep hdfs | awk -F":" '{print $1,$5}' | awk '{ if( $1=="hdfs"&&$2=="Hadoop") print "PASS: hdfs functional account correctly established."; else print "FAIL: hdfs functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep hive | awk -F":" '{print $1,$5}' | awk '{ if( $1=="hive"&&$2=="Hadoop") print "PASS: hive functional account correctly established."; else print "FAIL: hive functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep httpfs | awk -F":" '{print $1,$5}' | awk '{ if( $1=="httpfs"&&$2=="Hadoop") print "PASS: httpfs functional account correctly established."; else print "FAIL: httpfs functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep hue | awk -F":" '{print $1,$5}' | awk '{ if( $1=="hue"&&$2=="Hadoop") print "PASS: hue functional account correctly established."; else print "FAIL: hue functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep impala | awk -F":" '{print $1,$5}' | awk '{ if( $1=="impala"&&$2=="Hadoop") print "PASS: impala functional account correctly established."; else print "FAIL: impala functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep kafka | awk -F":" '{print $1,$5}' | awk '{ if( $1=="kafka"&&$2=="Hadoop") print "PASS: kafka functional account correctly established."; else print "FAIL: kafka functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep kms | awk -F":" '{print $1,$5}' | awk '{ if( $1=="kms"&&$2=="Hadoop") print "PASS: kms functional account correctly established."; else print "FAIL: kms functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep keytrustee | awk -F":" '{print $1,$5}' | awk '{ if( $1=="keytrustee"&&$2=="Hadoop") print "PASS: keytrustee functional account correctly established."; else print "FAIL: keytrustee functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep kudu | awk -F":" '{print $1,$5}' | awk '{ if( $1=="kudu"&&$2=="Hadoop") print "PASS: kudu functional account correctly established."; else print "FAIL: kudu functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep llama | awk -F":" '{print $1,$5}' | awk '{ if( $1=="llama"&&$2=="Hadoop") print "PASS: llama functional account correctly established."; else print "FAIL: llama functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep mapred | awk -F":" '{print $1,$5}' | awk '{ if( $1=="mapred"&&$2=="Hadoop") print "PASS: mapred functional account correctly established."; else print "FAIL: mapred functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep oozie | awk -F":" '{print $1,$5}' | awk '{ if( $1=="oozie"&&$2=="Hadoop") print "PASS: oozie functional account correctly established."; else print "FAIL: oozie functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep solr | awk -F":" '{print $1,$5}' | awk '{ if( $1=="solr"&&$2=="Hadoop") print "PASS: solr functional account correctly established."; else print "FAIL: solr functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep spark | awk -F":" '{print $1,$5}' | awk '{ if( $1=="spark"&&$2=="Hadoop") print "PASS: spark functional account correctly established."; else print "FAIL: spark functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep sentry | awk -F":" '{print $1,$5}' | awk '{ if( $1=="sentry"&&$2=="Hadoop") print "PASS: sentry functional account correctly established."; else print "FAIL: sentry functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep -w sqoop | awk -F":" '{print $1,$5}' | awk '{ if( $1=="sqoop"&&$2=="Hadoop") print "PASS: sqoop functional account correctly established."; else print "FAIL: sqoop functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep sqoop2 | awk -F":" '{print $1,$5}' | awk '{ if( $1=="sqoop2"&&$2=="Hadoop") print "PASS: sqoop2 functional account correctly established."; else print "FAIL: sqoop2 functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep yarn | awk -F":" '{print $1,$5}' | awk '{ if( $1=="yarn"&&$2=="Hadoop") print "PASS: yarn functional account correctly established."; else print "FAIL: yarn functional account not established correctly"}'`"

log_msg "`cat /etc/passwd | grep zookeeper | awk -F":" '{print $1,$5}' | awk '{if( $1=="zookeeper"&&$2=="Hadoop") print "PASS: zookeeper functional account correctly established."; else print "FAIL: zookeeper functional account not established correctly"}'`"

log_msg "`cat /etc/group | grep hdfs | grep hadoop | awk -F":" '{if( $4=="hdfs,mapred,yarn") print "PASS: hadoop group OK"; else print "FAIL: hadoop group NOK"}'`"

log_msg "`cat /etc/group | grep hive | awk -F":" '{if( $4=="impala") print "PASS: hive group OK"; else print "FAIL: hive group NOK"}'`"

log_msg "`cat /etc/group | grep sqoop: | awk -F":" '{if( $4=="sqoop2") print "PASS: sqoop group OK"; else print "FAIL: sqoop group NOK" }'`"

}


function check_mount_prev {
	prev=`ls -l /|grep 'data..'|cut -d' ' -f1|sort -u`
        if [ $prev = "drwxr-xr-x" ]
        then
		log_msg "PASS: All the mount permissions are good set to 755"
        else
                log_msg "FAIL: Mount point permissions are not set to 755"
		if [ $UPDATE ]
		then
			log_msg "Setting the required privileges"
			 chmod -R 755 /data??
			log_msg "PASS: Permissions are set correctly"
		fi
        fi
}

function jdk_install {
        JH=`echo $JAVA_HOME`
        if [ $JH == "/usr/java/latest" ]
        then
                log_msg "PASS: JAVA_HOME is set"
        else
                log_msg "FAIL: $JAVA_HOME is NOT set"
                if [ $UPDATE ]
                then
                	wget http://repository.rdip.gsk.com/hadoop-repo/java/java_home.sh -O /etc/profile.d/java_home.sh
                	chmod 755 /etc/profile.d/java_home.sh
                        echo $JAVA_HOME
                log_msg "PASS: JAVA_HOME is set correctly"
                fi
        fi
}
function java_home {
	JH=`echo $JAVA_HOME`
	if [[ `grep JAVA_HOME "/root/.bash_profile" | wc -l` -ne 0 ]]
	then
		log_msg "PASS: JAVA_HOME is set on `hostname -f`"
        else
                log_msg "FAIL: $JAVA_HOME is NOT set"
		if [ $UPDATE ]
		then
		    echo "# Added by RDIP Platform Team ******************" >> /root/.bash_profile
		    echo "export JAVA_HOME=/usr/java/latest" >> /root/.bash_profile
  		    echo "export PATH="\${JAVA_HOME}\/bin:\$PATH"" >> /root/.bash_profile
	 	    source /root/.bash_profile
		    java -version 		
		    log_msg "PASS: JAVA_HOME is set correctly"
		fi
	fi
}
function kerberos {
	krb5_wrkstn_pkg=`rpm -qa | grep krb5-workstation | wc -l`
	krb5_libs_pkg=`rpm -qa | grep krb5-libs | wc -l`
#krb5-libs-1.13.2-10.el7.i686	
    if [ ${krb5_wrkstn_pkg} -eq 1 ] 
	then
		 log_msg "PASS: krb5-workstation is Installed "
	else 
		 log_msg "FAIL: krb5-workstation is Installed"
		 if [ $UPDATE ]
		 then
		     yum install -y krb5-workstation
		     log_msg "PASS: krb5-workstation is installed"
		 fi
	
	fi
	if [ ${krb5_libs_pkg} -gt 1 ]
        then
                 log_msg "PASS: krb5_libs is Installed "
        else
                 log_msg "FAIL: krb5_libs is not Installed"
                 if [ $UPDATE ]
                 then
                     yum install -y krb5-libs
                     log_msg "PASS: krb5-libs is installed"
                 fi

        fi
}

function krb5 {
echo "."

}
function ulimit {
limit=`cat /proc/sys/fs/file-max`
	if [ ${limit} -lt 200000 ]
        then
                 log_msg "PASS: Ulimit is Set = ${limit}"
        else
                 log_msg "FAIL: Ulimit is set less than 200000"
                 if [ $UPDATE ]
                 then
                     if [ `grep fs.file-max /proc/sys/fs/file-max | wc -l` != "1"  ]
		             then
			     echo "fs.file-max = 200000" >> "/proc/sys/fs/file-max"	  

		            fi
                     log_msg "PASS: Ulimit increased to 200000"
                 fi
        fi
}

 
### main -- execution starts here
clear_log
log_msg "*******************************************"
log_msg "Starting Pre-Check on Node= `hostname -f` "
log_msg "Log file: ${LOG_FILE}"
log_msg " `date` "
log_msg "*******************************************"
vmswappiness
thp
ntpd
selinux
mail
nscdservice
firewall
hostsfile
fstabnoatime
entropycheck
diskblocksize
functionalUsers
check_mount_prev
jdk_install
java_home
kerberos
krb5
ulimit
nslookup
