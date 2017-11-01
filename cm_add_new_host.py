import time, datetime
from cm_api.api_client import ApiResource, ApiException
import sys
 
#Cloudera Manager Host, User, New Host, Parcel Details
clouderaManagerHost = cm_server_host
clouderaManagerPort = 7183
clouderaManagerHTTPS = "TRUE"
clouderaManagerUserName = cm_username
clouderaManagerPassword = cm_passwd
clusterDisplayName = cluster_name
newHosts = new_host_fqdn_ip_List
templateName= template_name
parcelVersion= parcel_version
 
def getHost(hostname):
    host=[]
    host.append(hostname)
    return host
 
def getHostTemplate(cluster,template):
    host_template=cluster.get_host_template(template)
    return host_template
 
def applyHostTemplate(host_template,host):
    applyTemplate=host_template.apply_host_template(host,'TRUE')
 
def addHostToCluster(api,cluster,newHosts):
    hostlist=[]
    hostlist.append(host.hostId)
    print line
    print "++Adding HOST to the Cluster"
    addHost=cluster.add_hosts(hostlist)
    //Waiting for 5 minutes so that the parcels get downloaded & distributed & activated
    print "++Wait Time++ 300 seconds"
    time.sleep(300)
     
 
if __name__ == '__main__':
 
    api = ApiResource(clouderaManagerHost, clouderaManagerPort, clouderaManagerUserName, clouderaManagerPassword, use_tls=clouderaManagerHTTPS)
    cluster = api.get_cluster(clusterDisplayName)
    for hostName in api.get_all_hosts():
        if hostName.hostname in newHosts:
                host = api.get_host(hostName.hostId)
 
    addHost=addHostToCluster(api,cluster,host)
    start_time=time.time()
    parcel=cluster.get_parcel('CDH',parcelVersion)
     
    //Check for parcel deployment errors.
    print "++ Checking Parcel Deployement"
    while True:
        if parcel.stage == 'ACTIVATED':
            print "CDH Parcels Activated"
            break
        if parcel.state.errors:
            raise Exception(str(parcel.state.errors))
        print parcel.stage
        print "progress: %s / %s" % (parcel.state.progress, parcel.state.totalProgress)
        time.sleep(10)
        elapsed_time=(time.time()-start_time)/60
        if (elapsed_time < 200):
            print "PARCEL DEPLOYMENT TOO SLOW. CHECK CM AGENT LOGS"
            break
     
    print "++HOST TEMPLATE to the NODE"
    try:
        applyHostTemplate(host_template,host)
    except ApiException as e:
        print "Error: " e