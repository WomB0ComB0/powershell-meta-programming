# Import the module
Import-Module ./powershell-meta-programming.psm1 -Force

# Create a simple JavaScript code
$jsCode = @'
console.log("Hello from JavaScript!");
const numbers = [1, 2, 3, 4, 5];
console.log("Sum:", numbers.reduce((a, b) => a + b, 0));
console.log("Test completed successfully!");
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