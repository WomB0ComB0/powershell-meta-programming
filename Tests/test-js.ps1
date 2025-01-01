Import-Module ./Powershell-Meta-Programming.psm1 -Force

# 2025

# Create a simple JavaScript code
$jsCode = @'
console.log(new Array.from({ length: 50 }).reduce((a, b) => a + b, 0))
'@

try {
    # Generate and execute the JavaScript code
    $result = New-MetaCode -Language "JavaScript" -Code $jsCode -Execute

    Write-Host "`nFile created at: $result" -ForegroundColor Green
} 
catch {
    # If Node.js is not installed, show installation instructions
    if ($_.Exception.Message -like "*Runtime 'node' not found*") {
        Write-Host "`nNode.js is not installed." -ForegroundColor Yellow
        Get-InstallInstructions -Language "JavaScript"
    }
    else {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}