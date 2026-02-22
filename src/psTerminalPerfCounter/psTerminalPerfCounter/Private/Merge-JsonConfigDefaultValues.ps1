function Merge-JsonConfigDefaultValues {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [pscustomobject] $CounterConfig
    )

    begin {

        if ( -not $(Test-Path -Path $script:JSON_DEFAULT_TEMPLATE_FILE -PathType Leaf) ) {
            THROW "Default value template not found in $script:JSON_DEFAULT_TEMPLATE_FILE"
        }

    }

    process {

        try {

            $CounterConfigDefaultVaules = Get-Content $script:JSON_DEFAULT_TEMPLATE_FILE | ConvertFrom-Json

        } catch {

            Write-Error "Error merging default counter values ($($_.Exception.Message))"

        }

    }

    end {

    }
}