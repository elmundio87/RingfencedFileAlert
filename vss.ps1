# declare the parameters #
Param(
    [string]$user="Guest",
    [string]$password = "saucy",
    [string]$repo = "\\EMSDEV01\EMS_SourceSafe"
)

[Environment]::SetEnvironmentVariable("SSUSER", $user, "Process")
[Environment]::SetEnvironmentVariable("SSPWD", $password,"Process")
[Environment]::SetEnvironmentVariable("SSDIR",$repo,"Process")

function isAComment($ringfenced_file){
    return ($ringfenced_file -eq "" -or $ringfenced_file -match "^#.*")
}

function isACheckedInFile($line){
      return ($line -match "Checked in.*" -and !($line -match ".* Version .*"))
}

function getFilename($output,$index){
        $dir = ($output[$index..($index+3)] -join "") -replace "Checked in ",""
        $dir = $dir -replace "Comment:.*",""
        $file = $output[$index - 3] -replace "\*",""
        $file = $file.trim()
        Write-Host "File changed:${dir}/${file}"
        return "${dir}/${file}"
}

$output = ss history -#100
$files = @()
$exitcode = 0

$line = ""
$index = 0

while(!($line -match ".* Version .*") -and $index -lt $output.length)
{
    $line = $output[$index]
    if(isACheckedInFile $line)
    {
        $files += getFilename $output $index
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