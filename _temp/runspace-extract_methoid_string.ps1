class klasse {
    [string]   $Name
    [int]      $Alter

    klasse([string]$name, [int]$alter) {
        $this.Name = $name
        $this.Alter = $alter
    }

    [int] Vorstellung() {
        Write-Host "$(Get-Date) - START: $($this.Name) - ThreadID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)" -ForegroundColor Green
        Start-Sleep 1
        Write-Host "$(Get-Date) - END: $($this.Name) - ThreadID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)" -ForegroundColor Red
        return 42
    }
}

function Get-MethodSourceCode {
    param(
        [string]$ScriptPath,
        [string]$ClassName,
        [string]$MethodName
    )

    # Parse the script file
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors)

    # Find the class definition
    $classAst = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.TypeDefinitionAst] -and
        $node.Name -eq $ClassName
    }, $true)

    if ($classAst) {
        # Find the specific method
        $methodAst = $classAst[0].Members | Where-Object {
            $_.Name -eq $MethodName -and
            $_ -is [System.Management.Automation.Language.FunctionMemberAst]
        }

        if ($methodAst) {
            # Extract method body source code (without the surrounding braces)
            $methodBody = $methodAst.Body
            $sourceCode = $methodBody.Extent.Text

            # Remove the outer braces { }
            $sourceCode = $sourceCode.Trim()
            if ($sourceCode.StartsWith('{') -and $sourceCode.EndsWith('}')) {
                $sourceCode = $sourceCode.Substring(1, $sourceCode.Length - 2).Trim()
            }

            return $sourceCode
        } else {
            Write-Error "Method '$MethodName' not found in class '$ClassName'"
            return $null
        }
    } else {
        Write-Error "Class '$ClassName' not found"
        return $null
    }
}

# Alternative: Extract from current script if class is defined in same file
function Get-MethodSourceFromCurrentScript {
    param(
        [string]$ClassName,
        [string]$MethodName
    )

    # Get the current script content
    $scriptContent = $MyInvocation.ScriptName
    if (-not $scriptContent -or -not (Test-Path $scriptContent)) {
        # If not in a script file, try to get from current session
        $scriptContent = Get-PSCallStack | Where-Object { $_.ScriptName } | Select-Object -First 1 -ExpandProperty ScriptName
    }

    if ($scriptContent -and (Test-Path $scriptContent)) {
        return Get-MethodSourceCode -ScriptPath $scriptContent -ClassName $ClassName -MethodName $MethodName
    } else {
        Write-Error "Cannot determine script file path"
        return $null
    }
}

# Example usage - save this script to a file first
$currentScript = $PSCommandPath
if ($currentScript) {
    $methodCode = Get-MethodSourceCode -ScriptPath $currentScript -ClassName "klasse" -MethodName "Vorstellung"

    Write-Host "Extracted Method Code:" -ForegroundColor Yellow
    Write-Host "===================="
    Write-Host $methodCode
    Write-Host "===================="

    # Now you can use this code to create dynamic functions
    $dynamicFunction = @"
function Invoke-Vorstellung {
    param(`$Name)
    $methodCode
}
"@

    Write-Host "`nGenerated Dynamic Function:" -ForegroundColor Cyan
    Write-Host $dynamicFunction
} else {
    Write-Host "This script needs to be saved to a file to extract method source code" -ForegroundColor Red

    # Alternative: Manually define the method code
    $manualMethodCode = @'
Write-Host "$(Get-Date) - START: $($this.Name) - ThreadID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)" -ForegroundColor Green
Start-Sleep 1
Write-Host "$(Get-Date) - END: $($this.Name) - ThreadID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)" -ForegroundColor Red
return 42
'@

    Write-Host "Manual Method Code:" -ForegroundColor Yellow
    Write-Host $manualMethodCode
}