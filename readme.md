# get-ctxLoadAndLE
Gathers server load, assigned LE, and active and disconnected sessions and emails a HTLM formatted report.

#Contributions to this script
I'd like to highlight the posts that helped me write this scrip below.
* http://powershell.com/cs/blogs/ebook/archive/2008/10/23/chapter-4-arrays-and-hashtables.aspx
* http://technet.microsoft.com/en-us/library/ff730946.aspx
* http://technet.microsoft.com/en-us/library/ff730936.aspx
* [test-port function] http://irl33t.com/blog/2011/03/powershell-script-connect-rdp-ps1
* http://carlwebster.com/finding-offline-servers-using-powershell-part-1-of-4/
* [get-uptime function] https://gallery.technet.microsoft.com/scriptcenter/Get-Uptime-PowerShell-eb98896f

# get-help .\get-ctxLoadAndLE.ps1 -full

NAME<br>
    get-ctxLoadAndLE.ps1
    
SYNOPSIS<br>
    Gathers server load, assigned LE, and active and disconnected sessions and emails a HTLM formatted report.
    
SYNTAX<br>
    PS> get-ctxLoadAndLE.ps1 [-DeliveryControllers] <Object> [<CommonParameters>]
    
DESCRIPTION<br>
    Gathers server load, assigned LE, and active and disconnected sessions and emails a HTLM formatted report. It is recommended that this script be run as a Citrix admin. In addition, the Citrix Powershell modules should be installed

PARAMETERS

    -DeliveryControllers <Object>
        Required parameter. Which Citrix Delivery Controller(s) (farm) to publish applicaiton with
        
        Required?                    true
        Position?                    1
        Default value                YOURDDC.DOMAIN.LOCAL
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216). 
    
INPUTS<br>
    None
	
OUTPUTS<br>
    An HTA file is created and used for the report email. The HTA file is saved to the $TEMP environment variable
    
NOTES
    
        NAME: get-ctxLoadAndLE.ps1
        VERSION: 1.09
        CHANGE LOG - Version - When - What - Who
        1.00 - 01/11/2012 -Initial script - Alain Assaf
        1.01 - 01/18/2012 - Changed way I get user sessions because it was timing out - Alain Assaf
        1.02 - 02/20/2012 - Added sendTo variable to add mulitple receipients - Alain Assaf
        1.03 - 03/05/2012 - Added lines to include LE Rules - Alain Assaf
        1.04 - 04/26/2012 - Added Test-Port function from Aaron Wurthmann (aaron (AT) wurthmann (DOT) com) - Alain 
        Assaf
        1.05 - 11/23/2016 - Added $DeliveryController var name for remoting to farm - Alain Assaf
        1.06 - 11/23/2016 - Added Carl Webster's logic to separate Offline and Online servers. Removed test-port 
        test. - Alain Assaf
        1.06 - 11/28/2016 - Added get-uptime function from Jason Wasser. - Alain Assaf
        1.07 - 12/06/2016 - Changed email routine to iterate through array of emails - Alain Assaf
        1.08 - 12/08/2016 - Changed Deliverycontrollers and added a test to ensure one is up before quering farm - 
        Alain Assaf
        1.09 - 03/21/2017 - updated modules to newer versions. Removed unused code - Alain Assaf
        AUTHOR: Alain Assaf
        LASTEDIT: March 21, 2017
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>PS C:\PSScript &amp;gt; .\get-ctxLoadAndLE.ps1
    
    Will use all default values.
    Will query servers in the default Farm and create an HTA file and optionally email the report.
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\PSScript>.\get-ctxLoadAndLE.ps1 -DeliveryController YOURDDC.DOMAIN.LOCAL
    
    Will use YOURDDC.DOMAIN.LOCAL for the delivery controller address.
    Will query servers in the YOURDDC.DOMAIN.LOCAL Farm and create an HTA file and optionally email the report.    
    
# Legal and Licensing
The get-ctxLoadAndLE.ps1 script is licensed under the [MIT license][].

[MIT license]: LICENSE

# Want to connect?
* LinkedIn - https://www.linkedin.com/in/alainassaf
* Twitter - http://twitter.com/alainassaf
* Wag the Real - my blog - https://wagthereal.com
* Edgesightunderthehood - my other - blog https://edgesightunderthehood.com

# Help
I welcome any feedback, ideas or contributors.
