# End-to-End SIEM Pipeline Lab (Logstash + OpenSearch + Atomic Red Team)

## Overview
This project demonstrates a fully functional, virtualized security lab designed to simulate real-world SIEM data flows, adversary techniques, and detection validation.  
The environment includes Linux and Windows virtual machines, a custom log ingestion pipeline, and adversary simulation using Atomic Red Team.

The objective of this lab is to showcase hands-on experience with log collection, parsing, enrichment, indexing, visualization, and detection engineering.

## Lab Environment

### Linux SIEM Server (Ubuntu) 
- 4 vCPUs
- 8 GB RAM
- 40 GB disk
- Services: Logstash, OpenSearch, OpenSearch Dashboards
 
### Windows Endpoint (Windows 10/11) 
- 2 vCPUs
- 4 GB RAM
- 40 GB disk
- Tools: Sysmon, Winlogbeat, Atomic Red Team
 
### Virtualization Platform
- Oracle VirtualBox
- Internal network for log forwarding and isolation

## Architecture
The lab consists of the following components:

- **Virtualization:** Oracle VirtualBox  
- **Log Processing:** Logstash (with Opensearch output plugin) 
- **Search & Indexing:** OpenSearch (version 2.11.1) 
- **Visualization:** OpenSearch Dashboards (version 2.11.1) 
- **Endpoint Telemetry:** Sysmon + Winlogbeat (Windows event forwarder / Advanced Windows event logging) 
- **Adversary Simulation:** Atomic Red Team  
- **Operating Systems:**  
  - Ubuntu Linux (SIEM server)  
  - Windows 10/11 (endpoint)

## Architecture Overview
[ Windows Endpoint ]
|
|  Winlogbeat + Sysmon
v
[ Logstash Server (Docker on Linux) ]
|
|  Parsed & Enriched Logs
v
[ OpenSearch ]
|
|  Dashboards & Visualizations
v
[ OpenSearch Dashboards ]

## Features

### Log Ingestion Pipeline
- Configured **Winlogbeat** to forward Windows Security, Sysmon, and PowerShell logs.
- Built Logstash pipelines for:
  - Parsing event logs  
  - Normalizing fields  
  - Tagging event types  
  - Forwarding data to OpenSearch  

### OpenSearch Configuration
- Created custom indices for Windows event logs.
- Tuned index templates and mappings.
- Built dashboards for:
  - Sysmon process creation  
  - PowerShell activity  
  - Authentication events  
  - Atomic Red Team telemetry  

### Adversary Simulation
Executed multiple **Atomic Red Team** tests to generate realistic attack telemetry, including:
- Credential access  
- Persistence techniques  
- Defense evasion  
- Lateral movement simulations  

Validated that logs were:
1. Generated on the endpoint  
2. Forwarded to Logstash  
3. Indexed in OpenSearch  
4. Visualized in dashboards  

## Configuration Files
This repository includes example configurations used in the lab:

**1. Logstash Configuration**
The logstash.conf file defines the Logstash pipeline responsible for receiving logs from Winlogbeat and forwarding them to OpenSearch.

The pipeline includes:

- Beats input on port 5044
- Optional filtering and event processing
- OpenSearch output using the official output plugin

This file is automatically loaded by the Logstash container when the Docker stack starts.

**2. Docker Compose**
The docker-compose.yml file orchestrates the entire backend stack:

- OpenSearch 2.11.1
- OpenSearch Dashboards 2.11.1

Start the stack:
**docker-compose up -d**

Stop the stack:
**docker-compose down**

**Access the services**
- OpenSearch API: http://localhost:9200
- OpenSearch Dashboards: http://localhost:5601

  
Winlogbeat + Sysmon (Windows Host)
On the Windows side, log collection is fully automated using a PowerShell script included in the repository.

The script performs:

- Winlogbeat installation
- Deployment of the Winlogbeat configuration
- Installation of Winlogbeat as a Windows service
- Installation of Sysmon using the provided configuration
- Service startup and connectivity checks to Logstash  

**Run the script (PowerShell as Administrator)**

**.\deploy_winlogbeat_with_sysmon**

This script handles the entire Windows setup with no manual steps required.

**Repository Structure**
/
├── docker-compose.yml        # OpenSearch + Dashboards + Logstash stack
├── logstash.conf             # Logstash pipeline configuration
├── deploy_winlogbeat_with_sysmon.ps1   # Automated Winlogbeat + Sysmon installer
└── README.md

**Testing the Pipeline**
Once the Windows script has been executed and the Docker stack is running:

1. Generate events on the Windows machine (PowerShell commands, process launches, network activity, Atomic Red Team)

2. Open OpenSearch Dashboards → Discover

Select the index pattern:
winlogbeat-*

You should see logs flowing in real time.

## Conclusion

This lab provides a complete, containerized SIEM environment that can be easily deployed, tested, and extended. It is designed for learning, experimentation, and demonstrating log collection and analysis using OpenSearch, Logstash, Winlogbeat, and Sysmon.
