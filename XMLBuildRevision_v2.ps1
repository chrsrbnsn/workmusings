 <#
{0} - Controller Name
{1} - Partition Key
{2} - ComBoard number, ComBoard SlotIndex
{3} - ACMBoard number, ACMBoard SlotIndex
{4} - Input Name
{5} - Input SlotIndex
#>

$csvPath = "C:\scripts\ps_input.csv"
$finalXML = "C:\scripts\output\run1.xml"
$xmlTemplatePath = "C:\scripts\XMLTemplate.xml"
[xml]$iStarTemplate = Get-Content $xmlTemplatePath

$script:iStarRoot =         "CrossFire"
$script:iStarInput =        "SoftwareHouse.NextGen.Common.SecurityObjects.iStarInput"
$script:iStarController =   "SoftwareHouse.NextGen.Common.SecurityObjects.iStarController"
$script:iStarComBoard =     "SoftwareHouse.NextGen.Common.SecurityObjects.iStarComBoard"
$script:iStarInputBoard =   "SoftwareHouse.NextGen.Common.SecurityObjects.iStarInputBoard"
$script:LastCx = $null
$script:LastACM = $null
$script:LastCBoard = $null
$script:iStarTemplate

function Set-LastUsed
{
    param($CX,$Board,$ACM)

    if($CX -ne $LastCx -and $CX -ne "")
    {
        $LastCx = $CX
    }

    if($ACM -ne $LastACM -and $ACM -ne "")
    {
        $LastACM = $ACM
    }

    if($Board -ne $LastBoard -and $Board -ne "")
    {
        $LastBoard = $Board
    }
}

function Set-iStarCX
{
    param($inputCSVobject,[xml]$oXML)

    $ClonedNode = $iStarTemplate.CrossFire.$iStarController.Clone()
    $ClonedNode.psobject.properties | Where-Object {$_.Value -match '\{[0-9]\}'} | ForEach-Object {$_.Value = $_.Value -f $($inputCSVobject.psobject.properties | ForEach-Object {$_.Value})}
    [void]$oXML.CrossFire.AppendChild($oXML.ImportNode($ClonedNode,$true))
    
    Set-LastUsed $inputCSVobject.Controller $inputCSVobject.Address $inputCSVobject.ACMnum
    
}

function Set-iStarComBoard
{
    param($inputCSVobject,[xml]$oXML)

    $ClonedNode = $iStarTemplate.CrossFire.$iStarController.$iStarComBoard.Clone()
    $ClonedNode.psobject.properties | Where-Object {$_.Value -match '\{[0-9]\}'} | ForEach-Object {$_.Value = $_.Value -f $($inputCSVobject.psobject.properties | ForEach-Object {$_.Value})}
    [void]$oXML.CrossFire.$iStarController.AppendChild($oXML.ImportNode($ClonedNode,$true))
        
    Set-LastUsed $inputCSVobject.Controller $inputCSVobject.Address $inputCSVobject.ACMnum
    
}

function Set-iStarInputBoard
{
    param($inputCSVobject,[xml]$oXML)

    $ClonedNode = $iStarTemplate.CrossFire.$iStarController.$iStarComBoard.$iStarInputBoard.Clone()
    $ClonedNode.psobject.properties | Where-Object {$_.Value -match '\{[0-9]\}'} | ForEach-Object {$_.Value = $_.Value -f $($inputCSVobject.psobject.properties | ForEach-Object {$_.Value})}
    [void]$oXML.CrossFire.$iStarController.$iStarComBoard.AppendChild($oXML.ImportNode($ClonedNode,$true))

    Set-LastUsed $inputCSVobject.Controller $inputCSVobject.Address $inputCSVobject.ACMnum
    
}


function Set-iStarInput
{
    param($inputCSVobject,[xml]$oXML)

    $ClonedNode = $iStarTemplate.CrossFire.$iStarController.$iStarComBoard.$iStarInputBoard.$iStarInput.Clone()
    $ClonedNode.psobject.properties | Where-Object {$_.Value -match '\{[0-9]\}'} | ForEach-Object {$_.Value = $_.Value -f $($inputCSVobject.psobject.properties | ForEach-Object {$_.Value})}
    [void]$oXML.CrossFire.$iStarController.$iStarComBoard.$iStarInputBoard.AppendChild($oXML.ImportNode($ClonedNode,$true))

    Set-LastUsed $inputCSVobject.Controller $inputCSVobject.Address $inputCSVobject.ACMnum

}

$xmlWrite = New-Object System.XMl.XmlTextWriter($finalXML,[System.Text.Encoding]::UTF8)  
$xmlWrite.Formatting = "Indented"  
$xmlWrite.Indentation = "2"  
$xmlWrite.WriteStartDocument($true)
$xmlWrite.WriteStartElement("CrossFire")  
$xmlWrite.WriteAttributeString("culture-info", "en-US")
$xmlWrite.WriteAttributeString("platform-version","2.40.8")
$xmlWrite.WriteAttributeString("product-version","2.40.8")
$xmlWrite.WriteEndElement()
$xmlWrite.WriteEndDocument()
$xmlWrite.Flush()  
$xmlWrite.Close()

[xml]$outXML = Get-Content $finalXML
$script:outXML

$csvInput = Import-Csv $csvPath

foreach($csv in $csvInput)
{
    if($csv.Controller -ne $LastCX -and $csv.Controller -ne "")
    {
        Set-iStarCX $csv $outXML
    }

    if($csv.ACMnum -ne $LastACM -and $csv.ACMnum -ne "")
    {
        Set-iStarComboard $csv $outXML
    }

    if($csv.Address -ne $LastBoard -and $csv.Address -ne "")
    {
        Set-iStarInputBoard $csv $outXML
    }

   if($csv.Name -ne "")
    {
        Set-iStarInput $csv $outXML
    }
}

$outXML.Save($finalXML)