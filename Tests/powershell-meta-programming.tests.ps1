#region Setup
BeforeAll {
    # Get the module path relative to the test file
    $modulePath = Join-Path $PSScriptRoot "../powershell-meta-programming.psm1"
    
    # Verify module path exists
    if (-not (Test-Path $modulePath)) {
        throw "Module path not found: $modulePath"
    }
    
    # Remove module if it exists
    Remove-Module powershell-meta-programming -ErrorAction SilentlyContinue
    
    # Import the module with verbose output
    Import-Module $modulePath -Force -Verbose
    
    # Verify functions are available
    $requiredFunctions = @('New-MetaCode', 'Invoke-MetaCode', 'Get-InstallInstructions')
    foreach ($func in $requiredFunctions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            throw "Function '$func' not found after module import"
        }
    }
}
#endregion

#region Tests
Describe "PowerShell Meta Programming Module" {
    Context "Module Configuration" {
        It "Should have valid module version" {
            $Script:ModuleVersion | Should -Not -BeNullOrEmpty
            $Script:ModuleVersion | Should -Match '^\d+\.\d+\.\d+$'
        }

        It "Should have non-empty supported languages list" {
            $Script:SupportedLanguages | Should -Not -BeNullOrEmpty
            $Script:SupportedLanguages.Count | Should -BeGreaterThan 0
        }

        It "Should have matching file extensions for all supported languages" {
            $Script:SupportedLanguages | ForEach-Object {
                $Script:FileExtensions.ContainsKey($_) | Should -BeTrue
                $Script:FileExtensions[$_] | Should -Not -BeNullOrEmpty
            }
        }

        It "Should have matching runtime commands for all supported languages" {
            $Script:SupportedLanguages | ForEach-Object {
                $Script:RuntimeCommands.ContainsKey($_) | Should -BeTrue
                $Script:RuntimeCommands[$_] | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "New-MetaCode Function" {
        BeforeAll {
            $TestOutputPath = Join-Path $TestDrive "meta_output"
        }

        It "Should create output directory if it doesn't exist" {
            New-MetaCode -Language "Python" -Code 'print("test")' -OutputPath $TestOutputPath
            Test-Path $TestOutputPath | Should -BeTrue
        }

        It "Should generate file with correct extension for Python" {
            $filepath = New-MetaCode -Language "Python" -Code 'print("test")' -OutputPath $TestOutputPath
            [System.IO.Path]::GetExtension($filepath) | Should -Be ".py"
        }

        It "Should generate file with correct extension for JavaScript" {
            $filepath = New-MetaCode -Language "JavaScript" -Code 'console.log("test")' -OutputPath $TestOutputPath
            [System.IO.Path]::GetExtension($filepath) | Should -Be ".js"
        }

        It "Should write correct content to file" {
            $testCode = 'print("Hello, World!")'
            $filepath = New-MetaCode -Language "Python" -Code $testCode -OutputPath $TestOutputPath
            Get-Content $filepath | Should -Be $testCode
        }

        It "Should throw on invalid language" {
            { New-MetaCode -Language "InvalidLanguage" -Code "test" -OutputPath $TestOutputPath } | 
                Should -Throw -ExpectedMessage "*is not supported*"
        }

        It "Should handle empty code" {
            { New-MetaCode -Language "Python" -Code "" -OutputPath $TestOutputPath } | 
                Should -Not -Throw
        }
    }

    Context "Invoke-MetaCode Function" {
        BeforeAll {
            $TestOutputPath = Join-Path $TestDrive "meta_output"
        }

        It "Should throw when runtime not found" {
            $filepath = New-MetaCode -Language "Python" -Code 'print("test")' -OutputPath $TestOutputPath
            Mock Get-Command { $false }
            { Invoke-MetaCode -Language "Python" -FilePath $filepath } | 
                Should -Throw "*Runtime 'python' not found*"
        }

        It "Should throw when file doesn't exist" {
            { Invoke-MetaCode -Language "Python" -FilePath "nonexistent.py" } | 
                Should -Throw
        }

        It "Should execute Python code successfully when runtime exists" {
            Mock Get-Command { $true }
            Mock Write-Host {} -ParameterFilter { $Object -like "*Executing Python code*" }
            
            $filepath = New-MetaCode -Language "Python" -Code 'print("test")' -OutputPath $TestOutputPath
            { Invoke-MetaCode -Language "Python" -FilePath $filepath } | Should -Not -Throw
            Should -Invoke Write-Host -ParameterFilter { $Object -like "*Executing Python code*" }
        }
    }

    Context "Get-InstallInstructions Function" {
        It "Should return instructions for supported languages" {
            $Script:SupportedLanguages | ForEach-Object {
                $instructions = Get-InstallInstructions -Language $_
                $instructions | Should -Not -BeNullOrEmpty
                $instructions | Should -Match $_ # Should mention the language
            }
        }

        It "Should return generic message for unknown language" {
            $instructions = Get-InstallInstructions -Language "UnknownLanguage"
            $instructions | Should -Match "Please install the appropriate runtime"
        }
    }

    Context "Integration Tests" {
        BeforeAll {
            $TestOutputPath = Join-Path $TestDrive "meta_output"
        }

        It "Should handle full workflow with Execute switch" {
            Mock Get-Command { $true }
            Mock Write-Host {}
            
            $testCode = 'print("Integration Test")'
            $filepath = New-MetaCode -Language "Python" -Code $testCode -OutputPath $TestOutputPath -Execute
            
            Test-Path $filepath | Should -BeTrue
            Get-Content $filepath | Should -Be $testCode
            Should -Invoke Write-Host -ParameterFilter { $Object -like "*Executing Python code*" }
        }
    }
}
#endregion

#region Cleanup
AfterAll {
    Remove-Module powershell-meta-programming -ErrorAction SilentlyContinue
}
#endregion