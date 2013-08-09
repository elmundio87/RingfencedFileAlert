#[Environment]::SetEnvironmentVariable("SSUSER", "testuser", "Process")
#[Environment]::SetEnvironmentVariable("SSPWD","1234","Process")
#[Environment]::SetEnvironmentVariable("SSDIR","\\VOSTRO_470_003\JenkinsTest","Process")

function isAComment($ringfenced_file){
    return ($ringfenced_file -eq "" -or $ringfenced_file -match "^#.*")
}

[Environment]::SetEnvironmentVariable("SSUSER", "Guest", "Process")
[Environment]::SetEnvironmentVariable("SSPWD","saucy","Process")
[Environment]::SetEnvironmentVariable("SSDIR","\\EMSDEV01\EMS_SourceSafe","Process")

$output = ss history -#100
$files = @()
$exitcode = 0

$line = ""
$index = 0

while(!($line -match ".* Version .*") -and $index -lt $output.length)
{
    $line = $output[$index]
    if($line -match "Checked in.*" -and !($line -match ".* Version .*"))
    {
        $dir = ($output[$index..($index+3)] -join "") -replace "Checked in ",""
        $dir = $dir -replace "Comment:.*",""
        $file = $output[$index - 3] -replace "\*\*\*\*\*",""
        $file = $file.trim()
        $files += "${dir}/${file}"
        Write-Host "File changed:${dir}/${file}"
    }
    $index++
}

$ringfenced_files = (Get-Content "ringfenced_files")
foreach ($ringfenced_file in $ringfenced_files) 
{ 
    if(!(isAComment $ringfenced_file))
    {
        foreach ($file in $files) 
        { 
            if($file -match $ringfenced_file)
            {
                $exitcode = 1
                Write-Warning "Change to ringfenced file: ${file} (RULE: ${ringfenced_file})"
            }
        }
    } 
} 

exit $exitcode