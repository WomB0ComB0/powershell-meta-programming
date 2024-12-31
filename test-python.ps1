Import-Module ./Powershell-Meta-Programming.psm1 -Force

$pythonCode = @'
print("Hello from Python!")
numbers = [1, 2, 3, 4, 5]
print(f"Sum: {sum(numbers)}")
print("Test completed successfully!")
'@

try {
    $result = New-MetaCode -Language "Python" -Code $pythonCode -Execute

    Write-Host "`nFile created at: $result" -ForegroundColor Green
} 
catch {
    if ($_.Exception.Message -like "*Runtime 'python' not found*") {
        Write-Host "`nPython is not installed." -ForegroundColor Yellow
        Get-InstallInstructions -Language "Python"
    }
    else {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}