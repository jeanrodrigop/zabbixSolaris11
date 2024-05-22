#!/bin/bash
# Install Zabbix Agent on Solaris x86|SPARC - JRodrigo
# Agent Version 4.0.34

# Agent version
agentVersion="4.0.34"

# Binaries
zabbixAgentX86="https://cdn.zabbix.com/zabbix/binaries/stable/4.0/4.0.34/zabbix_agent-4.0.34-solaris-11-i386-openssl.p5p"
zabbixAgentSPARC="https://cdn.zabbix.com/zabbix/binaries/stable/4.0/4.0.34/zabbix_agent-4.0.34-solaris-11-sparc-openssl.p5p"

# Directories creation
makeDirectories(){
    mkdir zabbix-agent
    mkdir /etc/zabbix

    clear
}

# Download and extract package
downloadBinary(){
    ARCH="$(uname -p)"
    echo -e "\nDownloading binaries for $ARCH arch...\n"
    
    case "$ARCH" in
        *86*)  # x86_64
            wget -P zabbix-agent/ "$zabbixAgentX86" || { echo "Error downloading binary." >&2; exit 1; }
            ;;
        *sparc*)  # SPARC
            wget -P zabbix-agent/ "$zabbixAgentSPARC" || { echo "Error downloading binary." >&2; exit 1; }
            ;;
        *)
            echo "Architecture not found." >&2
            exit 1
            ;;
    esac

    clear
}

# Add user, group
    echo -e "\nAdding user and group.\n"

userGroup(){
    groupadd -g 122 zabbix
    useradd -c 'Zabbix' -d / -g zabbix -s /usr/bin/false zabbix

    clear
}

# Create init.d script
installingAgent(){
    echo -e "\nInstalling Zabbix Agent $agentVersion...\n"

    pkg install -g zabbix-agent/zabbix_agent-*.p5p zabbix-agent

    clear
}

# Create zabbix config file
configExport(){
    echo -e "\nExporting zabbix service configuration...\n"

    svccfg export zabbix-agent

    clear
}

# Make log file, pid and give permissions
symbolicLink(){
    echo -e "\nCreating a symbolic link to '/etc/zabbix' directory...\n"

    ln -s /etc/opt/zabbix-agent/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf 

    clear
}

# Extra configurations
agentConfig(){  
    echo -e "\n< ============= ZABBIX CONFIGURATION ============= >\n"
    # Request user information
    read -p "Enter the server/proxy IP: " PROXY_IP
    read -p "Enter the host and client name(Hostname_MATRIX): " HOST_CLIENT
    
    # Apply configurations
    perl -pi -e 's/# LogFileSize=1/LogFileSize=10/' /etc/opt/zabbix-agent/zabbix_agentd.conf
    perl -pi -e 's/# EnableRemoteCommands=0/EnableRemoteCommands=1/' /etc/opt/zabbix-agent/zabbix_agentd.conf
    #perl -pi -e 's/Server=127\.0\.0\.1/Server=$PROXY_IP/' /etc/opt/zabbix-agent/zabbix_agentd.conf
    perl -pi -e 's/# StartAgents=3/StartAgents=5/' /etc/opt/zabbix-agent/zabbix_agentd.conf
    #perl -pi -e 's/ServerActive=127\.0\.0\.1/ServerActive=$PROXY_IP/' /etc/opt/zabbix-agent/zabbix_agentd.conf
    #perl -pi -e 's/Hostname=Zabbix\ server/Hostname=$HOST_CLIENT/' /etc/opt/zabbix-agent/zabbix_agentd.conf
    perl -pi -e 's/# Timeout=3/Timeout=30/' /etc/opt/zabbix-agent/zabbix_agentd.conf
    sed "s/Server=127\.0\.0\.1/Server=$PROXY_IP/" /etc/opt/zabbix-agent/zabbix_agentd.conf > /etc/opt/zabbix-agent/zabbix_agentd.conf.tmp && mv /etc/opt/zabbix-agent/zabbix_agentd.conf.tmp /etc/opt/zabbix-agent/zabbix_agentd.conf
    sed "s/ServerActive=127\.0\.0\.1/ServerActive=$PROXY_IP/" /etc/opt/zabbix-agent/zabbix_agentd.conf > /etc/opt/zabbix-agent/zabbix_agentd.conf.tmp && mv /etc/opt/zabbix-agent/zabbix_agentd.conf.tmp /etc/opt/zabbix-agent/zabbix_agentd.conf
    sed "s/Hostname=Zabbix\ server/Hostname=$HOST_CLIENT/" /etc/opt/zabbix-agent/zabbix_agentd.conf > /etc/opt/zabbix-agent/zabbix_agentd.conf.tmp && mv /etc/opt/zabbix-agent/zabbix_agentd.conf.tmp /etc/opt/zabbix-agent/zabbix_agentd.conf

    clear
}

# Start Zabbix Agent
startAgent(){
    echo -e "\nStarting Zabbix Agent...\n"
    
    svcadm restart zabbix-agent
    svcadm enable zabbix-agent

    clear
}

checkStatus(){
    status=$(svcs -l zabbix-agent | egrep '^state |^estado ' | awk '{print $2}')
    
    echo -e "\nChecking status... Zabbix Agent is $status!"
    echo -e "\nInstallation complete!\n"
}

makeDirectories 
downloadBinary 
userGroup       
installingAgent      
configExport 
symbolicLink  
agentConfig
startAgent
checkStatus