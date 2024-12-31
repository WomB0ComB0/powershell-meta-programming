#requires -version 7.4
#requires -modules Pester

# Module metadata
$Script:ModuleVersion = "1.0.0"
$Script:SupportedLanguages = @(
    'CPP', 'Java', 'Python', 'C', 'C#', 'JavaScript', 'TypeScript',
    'PHP', 'Swift', 'Kotlin', 'Dart', 'Go', 'Ruby', 'Scala',
    'Rust', 'Racket', 'Erlang', 'Elixir'
)

$Script:FileExtensions = @{
    'CPP' = 'cpp'
    'Java' = 'java'
    'Python' = 'py'
    'C' = 'c'
    'C#' = 'cs'
    'JavaScript' = 'js'
    'TypeScript' = 'ts'
    'PHP' = 'php'
    'Swift' = 'swift'
    'Kotlin' = 'kt'
    'Dart' = 'dart'
    'Go' = 'go'
    'Ruby' = 'rb'
    'Scala' = 'scala'
    'Rust' = 'rs'
    'Racket' = 'rkt'
    'Erlang' = 'erl'
    'Elixir' = 'ex'
}

$Script:RuntimeCommands = @{
    'Python' = 'python'
    'JavaScript' = 'node'
    'TypeScript' = 'tsc'
    'Ruby' = 'ruby'
    'PHP' = 'php'
    'C#' = 'dotnet'
    'CPP' = 'g++'
    'Java' = 'javac'
    'C' = 'gcc'
    'C++' = 'g++'
    'Kotlin' = 'kotlin'
    'Dart' = 'dart'
    'Go' = 'go'
    'Scala' = 'scala'
    'Rust' = 'rustc'
    'Racket' = 'racket'
    'Erlang' = 'erl'
    'Elixir' = 'elixir'
}

class ValidateLanguage : System.Management.Automation.ValidateArgumentsAttribute {
    # Constructor
    ValidateLanguage() : base() {}

    # Required abstract method implementation
    [void] Validate([System.Management.Automation.EngineIntrinsics]$engineIntrinsics) {
        $arguments = $engineIntrinsics.SessionState.PSVariable.GetValue("_")
        if ($arguments -is [array]) {
            foreach ($element in $arguments) {
                $this.ValidateElement($element)
            }
        } else {
            $this.ValidateElement($arguments)
        }
    }

    # Helper method for validation
    hidden [void] ValidateElement($element) {
        if ($null -eq $element) {
            throw [System.Management.Automation.ValidationMetadataException]::new(
                "Language cannot be null"
            )
        }
        if ($element -notin $Script:SupportedLanguages) {
            throw [System.Management.Automation.ValidationMetadataException]::new(
                "Language '$element' is not supported. Supported languages: $($Script:SupportedLanguages -join ', ')"
            )
        }
    }
}

function New-MetaCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet([ValidateLanguage])]
        [string]$Language,

        [Parameter(Mandatory = $true)]
        [string]$Code,

        [Parameter()]
        [string]$OutputPath = (Join-Path $PWD "meta_output"),

        [Parameter()]
        [switch]$Execute
    )

    try {
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath | Out-Null
        }

        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $extension = $FileExtensions[$Language]
        $filename = "meta_${Language}_${timestamp}.$extension"
        $filepath = Join-Path $OutputPath $filename

        $Code | Set-Content -Path $filepath -Encoding UTF8

        Write-Host "✅ Generated code file: $filepath" -ForegroundColor Green

        if ($Execute) {
            Invoke-MetaCode -Language $Language -FilePath $filepath
        }

        return $filepath
    }
    catch {
        Write-Error "Failed to generate meta code: $_"
        throw
    }
}

function Invoke-MetaCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet([ValidateLanguage])]
        [string]$Language,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [string]$FilePath
    )

    try {
        if (-not $RuntimeCommands.ContainsKey($Language)) {
            throw "Runtime execution not supported for $Language"
        }

        $runtime = $RuntimeCommands[$Language]
        if (-not (Get-Command $runtime -ErrorAction SilentlyContinue)) {
            $installInstructions = Get-InstallInstructions -Language $Language
            Write-Error "Runtime '$runtime' not found. $installInstructions"
            throw
        }

        Write-Host "🚀 Executing $Language code..." -ForegroundColor Cyan
        & $runtime $FilePath
        Write-Host "✅ Execution completed successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to execute meta code: $_"
        throw
    }
}

function Get-InstallInstructions {
    param (
        [string]$Language
    )

    $instructions = switch ($Language) {
        'Python' { "Install Python from https://www.python.org/downloads/" }
        'JavaScript' { "Install Node.js from https://nodejs.org/" }
        'TypeScript' { "Install TypeScript using npm: npm install -g typescript" }
        'Ruby' { "Install Ruby from https://www.ruby-lang.org/en/downloads/" }
        'PHP' { "Install PHP from https://www.php.net/downloads.php" }
        'C#' { "Install .NET SDK from https://dotnet.microsoft.com/download" }
        'CPP' { "Install GCC/G++ compiler" }
        'Java' { "Install Java Development Kit (JDK) from https://adoptium.net/" }
        'C' { "Install GCC compiler" }
        'Kotlin' { "Install Kotlin from https://kotlinlang.org/docs/command-line.html" }
        'Dart' { "Install Dart SDK from https://dart.dev/get-dart" }
        'Go' { "Install Go from https://golang.org/dl/" }
        'Scala' { "Install Scala from https://www.scala-lang.org/download/" }
        'Rust' { "Install Rust using rustup: https://rustup.rs/" }
        'Racket' { "Install Racket from https://racket-lang.org/" }
        'Erlang' { "Install Erlang from https://www.erlang.org/downloads" }
        'Elixir' { "Install Elixir from https://elixir-lang.org/install.html" }
        default { "Please install the appropriate runtime for $Language" }
    }

    return "To run $Language code, please install the required runtime:`n$instructions"
}

Export-ModuleMember -Function @('New-MetaCode', 'Invoke-MetaCode', 'Get-InstallInstructions')