################################################# Command Line Arguments #################################################
param (
  [parameter(Mandatory=$true)][string]$logstash_ip_addr,
  [parameter(Mandatory=$true)][string]$logstash_port
)

################################################# Global vars #################################################
$FILEBEAT_VERSION="7.10.0"

################################################# Install/Setup Osquery #################################################

#Install chocolatey
Write-Output "[+] - Installing chocolatey"
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

#Install osquery
Write-Output "[+] - Installing osquery"
choco install osquery --params='/InstallService'

cd 'C:\Program Files\osquery\'

#Download osquery.conf
Write-Output "[+] - Downloading file osquery.conf"
Invoke-WebRequest -Uri https://raw.githubusercontent.com/LorenaM22/osquery-filebeat-win/master/osquery.conf -OutFile osquery.conf

#Ejecutar osquery daemon
Write-Output "[+] - Starting osquery daemon"
Stop-service osqueryd
Start-service osqueryd

################################################# Install/Setup Filebeat #################################################
cd $home\Downloads

# Download Filebeat
Write-Output "[+] - Downloading Filebeat"
Invoke-WebRequest -Uri https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-$FILEBEAT_VERSION-windows-x86_64.zip -OutFile filebeat-$FILEBEAT_VERSION-windows-x86_64.zip

# Extract zip
Write-Output "[+] - Unzipping Filebeat"
Expand-Archive .\filebeat-$FILEBEAT_VERSION-windows-x86_64.zip -DestinationPath .

# Move directory
Write-Output "[+] - Moving filebeat directory to C:\Program Files\filebeat"
mv .\filebeat-$FILEBEAT_VERSION-windows-x86_64 'C:\Program Files\filebeat'
cd 'C:\Program Files\filebeat\'

# Get Winlogbeat config
cd 'C:\Program Files\filebeat'
Write-Output "[+] - Downloading filebeat config"
Invoke-WebRequest -Uri https://raw.githubusercontent.com/LorenaM22/osquery-filebeat-win/master/filebeat.yml -OutFile filebeat.yml

# Set Logstash server
Write-Output "[+] - Setting Logstash in filebeat config"
(Get-Content -Path .\filebeat.yml -Raw) -replace "logstash_ip_addr","$logstash_ip_addr" | Set-Content -Path .\filebeat.yml
(Get-Content -Path .\filebeat.yml -Raw) -replace "logstash_port","$logstash_port" | Set-Content -Path .\filebeat.yml

#Download certs
Write-Output "[+] - Downloading filebeat certs"
Invoke-WebRequest -Uri https://raw.githubusercontent.com/LorenaM22/osquery-filebeat-win/master/certs.zip -OutFile certs.zip
Expand-Archive .\certs.zip -DestinationPath ./certs

#osquery module
Write-Output "[+] - Downloading osquery module"
cd modules.d
Invoke-WebRequest -Uri https://raw.githubusercontent.com/LorenaM22/osquery-filebeat-win/master/osquery.yml -OutFile osquery.yml
cd.. 

# Install filebeat
Write-Output "[+] - Install filebeat as a service"
.\install-service-filebeat.ps1

# Start filebeat service
Write-Output "[+] - Start filebeat service"
Start-Service filebeat


