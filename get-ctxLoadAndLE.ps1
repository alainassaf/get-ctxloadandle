<#
.SYNOPSIS
 Gathers server load, assigned LE, and active and disconnected sessions and emails a HTLM formatted report.
.DESCRIPTION
 Gathers server load, assigned LE, and active and disconnected sessions and emails a HTLM formatted report. It is recommended that this script be run as a Citrix admin. In addition, the Citrix Powershell modules should be installed 
.PARAMETER DeliveryControllers
 Required parameter. Which Citrix Delivery Controller(s) (farm) to publish applicaiton with 
.EXAMPLE
 PS C:\PSScript> .\get-ctxLoadAndLE.ps1
 
 Will use all default values.
 Will query servers in the default Farm and create an HTA file and optionally email the report.
.EXAMPLE
 PS C:\PSScript> .\get-ctxLoadAndLE.ps1 -DeliveryController YOURDDC.DOMAIN.LOCAL 
 
 Will use YOURDDC.DOMAIN.LOCAL for the delivery controller address.
 Will query servers in the YOURDDC.DOMAIN.LOCAL Farm and create an HTA file and optionally email the report.
.OUTPUTS
 An HTA file is created and used for the report email. The HTA file is saved to the $TEMP environment variable
.NOTES
 NAME: get-ctxLoadAndLE.ps1
 VERSION: 1.15
 CHANGE LOG - Version - When - What - Who
 1.00 - 01/11/2012 -Initial script - Alain Assaf
 1.01 - 01/18/2012 - Changed way I get user sessions because it was timing out - Alain Assaf
 1.02 - 02/20/2012 - Added sendTo variable to add mulitple receipients - Alain Assaf
 1.03 - 03/05/2012 - Added lines to include LE Rules - Alain Assaf
 1.04 - 04/26/2012 - Added Test-Port function from Aaron Wurthmann (aaron (AT) wurthmann (DOT) com) - Alain Assaf
 1.05 - 11/23/2016 - Added $DeliveryController var name for remoting to farm - Alain Assaf
 1.06 - 11/23/2016 - Added Carl Webster's logic to separate Offline and Online servers. Removed test-port test. - Alain Assaf
 1.06 - 11/28/2016 - Added get-uptime function from Jason Wasser. - Alain Assaf
 1.07 - 12/06/2016 - Changed email routine to iterate through array of emails - Alain Assaf
 1.08 - 12/08/2016 - Changed Deliverycontrollers and added a test to ensure one is up before quering farm - Alain Assaf
 1.09 - 03/21/2017 - updated modules to newer versions. Removed unused code - Alain Assaf
 1.10 - 03/21/2016 - Used ctxModules to import functions and move them out of script - Alain Assaf
 1.11 - 03/21/2016 - Removed some links that are for functions. See ctxModules for the links - Alain Assaf
 1.12 - 03/21/2016 - Removed unused code - Alain Assaf
 1.13 - 03/28/2016 - Replaced Logon state column with Worker Group - Alain Assaf
 1.14 - 03/28/2016 - Added steps to deal with a server in more than one Worker Group - Alain Assaf
 1.15 - 04/04/2016 - Removed ctxmodules and put functions into script due to issues on server - Alain Assaf
 AUTHOR: Alain Assaf
 LASTEDIT: April 04, 2017
.LINK
 http://www.linkedin.com/in/alainassaf/
 http://wagthereal.com
 http://powershell.com/cs/blogs/ebook/archive/2008/10/23/chapter-4-arrays-and-hashtables.aspx
 http://technet.microsoft.com/en-us/library/ff730946.aspx
 http://technet.microsoft.com/en-us/library/ff730936.aspx
 [test-port function] http://irl33t.com/blog/2011/03/powershell-script-connect-rdp-ps1
 http://carlwebster.com/finding-offline-servers-using-powershell-part-1-of-4/
 [get-uptime function] https://gallery.technet.microsoft.com/scriptcenter/Get-Uptime-PowerShell-eb98896f
 http://matthewyarlett.blogspot.com/2014/10/powershell-array-to-comma-separated.html
#>
Param(
 [parameter(Position = 0, Mandatory=$True )]
 [ValidateNotNullOrEmpty()]
 $DeliveryControllers="YOURDDC.DOMAIN.LOCAL" # Change to hardcode a default value for your Delivery Controller
 )
 
#Constants
$PSSnapins = ("*citrix*")
#$ErrorActionPreference= 'silentlycontinue'
 
#Assign e-mail(s) to $sendto variable and SMTP server to $SMTPsrv
$sendto = "CITRIXTEAM@DOMAIN.LOCAL"
$from = "citrix@DOMAIN.LOCAL"
$SMTPsrv = "SMTP.DOMAIN.LOCAL" #Changed to your local SMTP server for email report

### START FUNCTION: get-mysnapin ##############################################
Function Get-MySnapin {
<#
    .SYNOPSIS
    Checks for a PowerShell Snapin(s) and imports it if available, otherwise it will display a warning and exit.
    .DESCRIPTION
    Checks for a PowerShell Snapin(s) and imports it if available, otherwise it will display a warning and exit.
    .PARAMETER snapins
    Required parameter. List of PSSnapins separated by commas.
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    PS> get-MySnapin PSSNAPIN
    Checks system for installed PSSNAPIN and imports it if available.
    .LINK
    http://www.linkedin.com/in/alainassaf/
    http://wagthereal.com
    https://github.com/alainassaf/get-mysnapin
    .NOTES
    NAME        :  Get-MySnapin
    VERSION     :  1.00
    CHANGE LOG - Version - When - What - Who
    1.00 - 02/13/2017 - Initial script - Alain Assaf
    LAST UPDATED:  02/13/2017
    AUTHOR      :  Alain Assaf
#>
    Param([string]$snapins)
        $ErrorActionPreference= 'silentlycontinue'
        foreach ($snap in $snapins.Split(",")) {
            if(-not(Get-PSSnapin -name $snap)) {
                if(Get-PSSnapin -Registered | Where-Object { $_.name -like $snap }) {
                    add-PSSnapin -Name $snap
                    $true
                }                                                                           
                else {
                    write-warning "$snap PowerShell Cmdlet not available."
                    write-warning "Please run this script from a system with the $snap PowerShell Cmdlet installed."
                    exit 1
                }                                                                           
            }                                                                                                                                                                  
        }
}
### END FUNCTION: get-mysnapin ################################################

### START FUNCTION: test-port ######################################################
# Function to test RDP availability
# Written by Aaron Wurthmann (aaron (AT) wurthmann (DOT) com)
function Test-Port{
    Param([string]$srv=$strhost,$port=3389,$timeout=300)
    $ErrorActionPreference = "SilentlyContinue"
    $tcpclient = new-Object system.Net.Sockets.TcpClient
    $iar = $tcpclient.BeginConnect($srv,$port,$null,$null)
    $wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
    if(!$wait) {
        $tcpclient.Close()
        Return $false
    } else {
        $error.Clear()
        $tcpclient.EndConnect($iar) | out-Null
        Return $true
        $tcpclient.Close()
    }
}
### END FUNCTION: test-port ########################################################

### START FUNCTION: get-uptime ################################################
Function Get-Uptime { 
<#
    .SYNOPSIS
    Gets uptime of server.
    .DESCRIPTION
    Gets uptime of server.
    .PARAMETER ComputerName
    Optional parameter. Server to get uptime from
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    PS> Get-Uptime SERVERNAME
    Test TCP connection to SERVERNAME over port 3389 with a 300 millisecond timeout
    .LINK
    http://www.linkedin.com/in/alainassaf/
    http://wagthereal.com
    https://gallery.technet.microsoft.com/scriptcenter/Get-Uptime-PowerShell-eb98896f
    .NOTES
    NAME        :  Get-Uptime
    VERSION     :  1.00
    CHANGE LOG - Version - When - What - Who
    1.00 - 02/13/2017 - Initial script - Alain Assaf
    LAST UPDATED:  02/13/2017
    AUTHOR      :  Alain Assaf
#>
    [CmdletBinding()] 
    param ( 
        [Parameter(Mandatory=$false, 
                        Position=0, 
                        ValueFromPipeline=$true, 
                        ValueFromPipelineByPropertyName=$true)] 
        [Alias("Name")] 
        [string[]]$ComputerName=$env:COMPUTERNAME, 
        $Credential = [System.Management.Automation.PSCredential]::Empty 
        ) 
 
    begin{} 
 
    #Need to verify that the hostname is valid in DNS 
    process { 
        foreach ($Computer in $ComputerName) { 
            try { 
                $hostdns = [System.Net.DNS]::GetHostEntry($Computer) 
                $OS = Get-WmiObject win32_operatingsystem -ComputerName $Computer -ErrorAction Stop -Credential $Credential 
                $BootTime = $OS.ConvertToDateTime($OS.LastBootUpTime) 
                $Uptime = $OS.ConvertToDateTime($OS.LocalDateTime) - $boottime 
                $propHash = [ordered]@{ 
                    ComputerName = $Computer 
                    BootTime     = $BootTime 
                    Uptime       = $Uptime 
                    } 
                $objComputerUptime = New-Object PSOBject -Property $propHash 
                $objComputerUptime 
                }  
            catch [Exception] { 
                Write-Output "$computer $($_.Exception.Message)" 
                #return 
                } 
        } 
    } 
    end{} 
}
### END FUNCTION: get-uptime ##################################################

### START FUNCTION: get-xmlbroker #############################################
Function Get-xmlbroker { 
<#
    .SYNOPSIS
    Gets responsive Citrix XML Broker.
    .DESCRIPTION
    Gets responsive Citrix XML Broker.
    .PARAMETER XMLBrokers
    Required parameter. Server to use as an XML Broker. Can be a list separated by commas.
    .INPUTS
    None
    .OUTPUTS
    None
    .EXAMPLE
    PS> Get-xmlbroker SERVERNAME
    Query SERVERNAME to see if it responsive. Assumes that SERVERNAME is a Citrix XML Broker
    .LINK
    http://www.linkedin.com/in/alainassaf/
    http://wagthereal.com
    .NOTES
    NAME        :  Get-xmlbroker
    VERSION     :  1.00
    CHANGE LOG - Version - When - What - Who
    1.00 - 03/08/2017 - Initial script - Alain Assaf
    LAST UPDATED:  03/08/2017
    AUTHOR      :  Alain Assaf
#>
    [CmdletBinding()] 
    param ([parameter(Position = 0, Mandatory=$False)]
           [ValidateNotNullOrEmpty()]
           $XMLBrokers
    )
            
    $DC = $XMLBrokers.Split(",")
    foreach ($broker in $DC) {
        if ((Test-Port $broker) -and (Test-Port $broker -port 1494) -and (Test-Port $broker -port 2598))  {
            $XMLBroker = $broker
            break
        }
    }
    Return $XMLBroker
}
### END FUNCTION: get-xmlbroker ###############################################
 
#Import Module(s) and Snapin(s)
get-MySnapin $PSSnapins

#Find an XML Broker that is up
$DeliveryController = Get-xmlbroker $DeliveryControllers

#Initialize array
$finalout = @()
 

$AllXAServers = Get-XAServer -ComputerName $DeliveryController | Sort-Object ServerName
$XAServers = @()
ForEach( $XAServer in $AllXAServers ) {
   $XAServers += $XAServer.ServerName
}

$OnlineXAServers = Get-XAzone -ComputerName $DeliveryController | Get-XAServer -ComputerName $DeliveryController -OnlineOnly | Sort-Object ServerName
$OnlineServers = @()
ForEach ($OnlineServer in $OnlineXAServers) {
   $OnlineServers += $OnlineServer.ServerName
}

$OfflineServers = @()
ForEach( $Server in $XAServers ) {
    If ($OnLineServers -notcontains $Server) {
        $OfflineServers += $Server
    }
}

 
#Get user sessions
$ctxsrvSessions = Get-XASession -ComputerName $DeliveryController | select -property SessionID,ServerName,AccountName,Protocol,State| where {($_.State -eq 'Active' -or $_.State -eq 'Disconnected') -and $_.Protocol -eq 'Ica'}
 
#Create a new object array with all the data we need
foreach ($srv in $AllXAServers) {
    $ctxsrv = $srv.servername
    #if (test-port $ctxsrv) {
    if ($OnlineServers -contains $ctxsrv) {
        $srvload = get-xaserverload -ComputerName $DeliveryController -servername $ctxsrv | select -Property ServerName,Load
        $srvinfo = get-xaserver -ComputerName $DeliveryController -servername $ctxsrv | select -Property LogOnMode,LogOnsEnabled
        $srvwg = (Get-XAWorkerGroup -ComputerName $DeliveryController -ServerName $ctxsrv).Workergroupname
        $wg = $null
        if ($srvwg.count -gt 1) {
            $srvwg | %{$wg += ( $( if($wg){", "}) + $_)}
        } else {
            $wg = $srvwg
        }
        $srvactive = @($ctxsrvSessions | where {$_.Servername -eq $ctxsrv -and $_.State -eq 'Active'}).count
        $srvdisconn = @($ctxsrvSessions | where {$_.Servername -eq $ctxsrv -and $_.State -eq 'Disconnected'}).count
        $srvuptime = get-uptime -name $ctxsrv
        $objctxsrv = new-object System.Object
        $objctxsrv | Add-Member -type NoteProperty -name ServerName -value $srvload.servername
        $objctxsrv | Add-Member -type NoteProperty -name Status -value "Running"
        $objctxsrv | Add-Member -type NoteProperty -name Load -value $srvload.Load
        $objctxsrv | Add-Member -type NoteProperty -name Active -value $srvactive
        $objctxsrv | Add-Member -type NoteProperty -name Disconnected -value $srvdisconn
        $objctxsrv | Add-Member -type NoteProperty -name 'Logon Mode' -value $srvinfo.LogOnMode.ToString()
        $objctxsrv | Add-Member -type NoteProperty -name 'Worker Group' -value $wg
        $objctxsrv | Add-Member -type NoteProperty -name 'Boot Time' -value ($srvuptime.BootTime).ToString()
        $tmpuptime = $srvuptime.Uptime.Days.ToString() + " days " + $srvuptime.Uptime.hours.ToString() + ":" + $srvuptime.Uptime.Minutes + " hours"  
        $objctxsrv | Add-Member -type NoteProperty -name 'Uptime' -value $tmpuptime
        $finalout += $objctxsrv
        write-verbose $finalout.count
    } else {
        $objctxsrv = new-object System.Object
        $objctxsrv | Add-Member -type NoteProperty -name ServerName -value $ctxsrv
        $objctxsrv | Add-Member -type NoteProperty -name Status -value "OFFLINE"
        $objctxsrv | Add-Member -type NoteProperty -name Load -value $null
        $objctxsrv | Add-Member -type NoteProperty -name Active -value $null
        $objctxsrv | Add-Member -type NoteProperty -name Disconnected -value $null
        $objctxsrv | Add-Member -type NoteProperty -name 'Logon Mode' -value $null
        $objctxsrv | Add-Member -type NoteProperty -name 'Worker Group' -value $null
        $objctxsrv | Add-Member -type NoteProperty -name 'Boot Time' -value $null
        $objctxsrv | Add-Member -type NoteProperty -name 'Uptime' -value $null
        $finalout += $objctxsrv
        write-verbose $finalout.count
    }
}

write-verbose "Got through server list"

#Create HTML Header
$head = '<style>
META{http-equiv:refresh content:30;}
BODY{font-family:Verdana;}
TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH{font-size:12px; border-width: 1px;padding: 2px;border-style: solid;border-color: black;background-color:PaleTurquoise}
TD{font-size:12px; border-width: 1px;padding: 2px;border-style: solid;border-color: black;background-color:GhostWhite}
</style>
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script> 
<script type="text/javascript">
$(function(){
var linhas = $("table tr");
$(linhas).each(function(){
var Valor = $(this).find("td:nth-child(2)").html();
if(Valor == "OFFLINE"){
  $(this).find("td").css("background-color","LightCoral");
}else if(Valor == "Running"){
  $(this).find("td").css("background-color","LightGreen");
}
});
});
</script>
'

$finalout = $finalout | sort 'Worker Group'

#Uncomment below to email a report
$title = "XenApp DASHBOARD"
#$body = $finalout | ConvertTo-Html -head $head -body $header -title $title
#$body = $finalout | ConvertTo-Html -head $head -title $title
 
#foreach ($email in $sendto) {
#    $smtpTo = $email
#    $smtpServer = $SMTPsrv
#    $smtpFrom = $from
#    $messageSubject = "Report: Server Load and Logon Mode for SECU XenApp 6.5 Farm"
#    $date = get-date -UFormat "%d.%m.%y - %H.%M.%S"
#    $relayServer = (test-connection $smtpServer -count 1).IPV4Address.tostring()
    
#    $message = New-Object System.Net.Mail.MailMessage $smtpfrom, $smtpto
#    $message.Subject = $messageSubject
#    $message.IsBodyHTML = $true
        
#    $message.Body = $finalout | ConvertTo-Html -head $head -title $title | out-string

#    $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
#    $smtp.Send($message) 
#}
 
#Uncomment to output the results in an HTA file to view in a browser
$finalout | ConvertTo-Html -head $head -title $title | out-file $env:temp\report.hta
ii $env:temp\report.hta
