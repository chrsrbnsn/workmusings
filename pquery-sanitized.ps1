# use portqry to test firewall rulesets on bulk machines for different purposes

# read in protocol and flows file
$protoFile = Get-Content .\protocol_flows.json -raw | ConvertFrom-Json

# read in hosts (destinations)
$hostsFile = Get-Content .\hosts.json -raw | ConvertFrom-Json

# identify host role based on naming convention (portqry source)
function Get-HostType {
    switch -regex ($env:COMPUTERNAME) {
        '^\w{2}\d\w{3}(?i)<Role Type>\d{3}$' { $rHost = <Role Type>; break  }
        '^\w{2}\d\w{3}(?i)<Role Type>\d{3}$' { $rHost = <Role Type>; break  }
        Default { $rHost = 'WKS' }
    }
    return $rHost
}

# TODO: <turn into function -- begin> build a relevant custom json file based on source and destination roles to run multiple portqry flow tests
$pquery = <portqry directory>
$sourceType = Get-HostType
$pqry_json = @()
$srcQuery = $protoFile | Where-Object Source -eq $sourceType
$hosts = $hostsFile | Where-Object { $_.Type -eq $sourceType }

foreach ( $h in $hosts.IP) {
    foreach ( $s in $srcQuery) {
        $scratch = "" | Select-Object IP,Port,Protocol
        $scratch.IP = $h
        $scratch.Port = $($s.Port)
        $scratch.Protocol = $($s.Protocol)
        $pqry_json += $scratch
    }
}

# build json for later use/reference
$pqry_json | ConvertTo-Json | Out-File ./pqry_params.json

# <end>

# TODO: <turn into function> run portqry with generated json and output results into log
foreach ($qry in $pqry_json){
    Write-Output "Querying IP: $($qry.IP) Port: $($qry.Port) Protocol: $($qry.Protocol)"
    Write-Verbose "`n -------> Querying IP: $($qry.IP) Port: $($qry.Port) Protocol: $($qry.Protocol) :: $(Get-Date) <--------"  -Verbose 4>> .\"$($env:COMPUTERNAME)_Query.log"
    & $pquery -n $($qry.IP) -e $($qry.Port) -p $($qry.Protocol) | Out-File -Append .\"$($env:COMPUTERNAME)_Query.log"
}

