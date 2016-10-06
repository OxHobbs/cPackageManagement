enum Ensure 
{
    Present
    Absent
}

enum InstallationPolicy
{
    Trusted
    Untrusted
}

[DscResource()]
class cPSRepository
{
    [DscProperty(Key)]
    [String] $Name

    [DscProperty()]
    [Ensure] $Ensure = 'Present'

    [DscProperty(Mandatory)]
    [String] $SourceLocation

    [DscProperty()]
    [String] $PublishLocation

    [DscProperty()]
    [String] $ScriptSourceLocation

    [DscProperty()]
    [String] $ScriptPublishLocation

    [DscProperty()]
    [InstallationPolicy] $InstallationPolicy = 'Untrusted'

    [DscProperty()]
    [String] $PackageManagementProvider = 'nuget'

    [cPSRepository] Get()
    {
        return $this
    }

    [bool] Test()
    {
        Write-Verbose "Running the Test method."
        $repo = Get-PSRepository -Name $this.Name -ErrorAction SilentlyContinue

        if ($this.Ensure -eq 'Present')
        {
            Write-Verbose "Ensure is set to Present"
            if (-not $repo) { Write-Verbose -Message "The repo does not exist."; return $false }
            Write-Verbose "Repo properties --> $($repo.Name) $($repo.SourceLocation)"
            if (
                ($repo.InstallationPolicy -ne $this.InstallationPolicy) -or
                ($repo.PackageManagementProvider -ne $this.PackageManagementProvider) -or
                ($repo.SourceLocation -ne $this.SourceLocation) -or
                ($repo.PublishLocation -ne $this.PublishLocation) -or
                ($repo.ScriptSourceLocation -ne $this.ScriptSourceLocation) -or
                ($repo.ScriptPublishLocation -ne $this.ScriptPublishLocation) 

            )
            {
                Write-Verbose "PS Respository ($($this.Name)) is registered but has some incorrect settings."
                return $false
            }
            Write-Verbose "PS Repository ($($this.Name)) already exists with the correct properties."
            return $true
        }
        else
        {
            if (-not $repo) { return $true }
            return $false
        }

    }

    [void] Set()
    {
        Write-Verbose "Running the Set method"

        $repo = Get-PsRepository -Name $this.Name -ErrorAction SilentlyContinue

        if ($this.Ensure -eq 'Present')
        {
            # hash the required/defaulted parameters
            $params = @{
                Name                      = $this.Name
                SourceLocation            = $this.SourceLocation
                InstallationPolicy        = $this.InstallationPolicy
                PackageManagementProvider = $this.PackageManagementProvider
            }

            # add optional specified parameters to hash
            if ($this.PublishLocation)       { $params.Add('PublishLocation', $this.PublishLocation) }
            if ($this.ScriptPublishLocation) { $params.Add('ScriptPublishLocation', $this.ScriptPublishLocation) }
            if ($this.ScriptSourceLocation)  { $params.Add('ScriptSourceLocation', $this.ScriptSourceLocation) }

            if ($repo)
            {
                Write-Verbose "The repo ($($this.Name)) exists, will use Set-PSRepository to correct incorrect settings."
                Set-PsRepository @params
            }
            else 
            {
                Write-Verbose "The repo ($($this.Name)) does not exist yet, it will be registered"
                Register-PSRepository @params
            }
        }
        else
        {
            Write-Verbose "The repo ($($this.Name)) will be unregistered."
            Unregister-PSRepository -Name $this.Name 
        }
    }
}

[DscResource()]
class cNugetInitPackages
{
    [DscProperty(Key)]
    [String] $SourceDirectory

    [DscProperty(Mandatory)]
    [String] $DestinationDirectory

    [DscProperty()]
    [String] $NuGetExePath

    [cNugetInitPackages] Get()
    {
        return $this
    }

    [void] Set()
    {
        $nugetExe = "nuget.exe"
        if ($this.NuGetExePath)
        {
            $nugetExe = $this.NuGetExePath
        }

        $src = (Get-ChildItem -Path $this.SourceDirectory).Directory.FullName | select -Unique
        $dest = (Get-Item -Path $this.DestinationDirectory).FullName | select -Unique
        Start-Process -FilePath $nugetExe -ArgumentList "init $src $dest" -Wait
    }

    [bool] Test()
    {
        $src = $this.SourceDirectory
        $dest = $this.DestinationDirectory

        if ((Test-Path $src) -and (Test-Path $dest))
        {
            Write-Verbose "Both the source and destination directories were found."
            $srcCount = (Get-ChildItem -Path $src).Count
            $destCount = ((Get-ChildItem -Path $dest) | Where name -notlike "*.bin").Count
            if ($srcCount -eq $destCount) 
            {
                Write-Verbose "It appears the same amount of packages are registered in both the source and the destination directories." 
                return $true 
            }
            else 
            {
                Write-Verbose "Source has $srcCount items.  Destination has $destCount items." 
                return $false 
            }
        }
        else 
        {
            Write-Error "The Source or Destination Directory does not exist"
            return $false
        }
        return $false
    }
}

[DscResource()]
class cPublishPSModule
{
    [DscProperty(Key)]
    [String] $Name

    [DscProperty()]
    [String] $PSRepository = 'PSGallery'

    [DscProperty()]
    [String] $NuGetApiKey

    [DscProperty()]
    [String] $ProjectUri

    [DscProperty()]
    [String] $LicenseUri
    
    [DscProperty()]
    [String] $IconUri

    [DscProperty()]
    [Version] $RequiredVersion

    [DscProperty()]
    [Version] $FormatVersion

    [DscProperty()]
    [String[]] $ReleaseNotes

    [DscProperty()]
    [String[]] $Tags

    [DscProperty(NotConfigurable)]
    [String] $ErrorTrace = ''

    [cPublishPSModule] Get()
    {
        return $this
    }

    [bool] Test()
    {
        if ($this.VerifyParams())
        {
            $params = $this.CollectParams('Find')
            if (Find-Module @params -ErrorAction SilentlyContinue)
            {
                return $true
            }
        }
        return $false
    }

    [void] Set()
    {
        if ($this.VerifyParams())
        {
            $params = $this.CollectParams('All')
            Publish-Module @params 
        }
        else
        {
            Write-Error $this.ErrorTrace
        }

    }

    [void] AddTrace($Message)
    {
        $this.ErrorTrace += ($Message + ';`n')
    }

    [bool] VerifyPsRepo()
    {
        if (Get-PSRepository -Name $this.Name -ErrorAction SilentlyContinue) 
        {
            Write-Verbose "The PowerShell Repository is registered"
            return $true
        }    
        AddTrace("The PS Repository ($($this.PSRepository)) does not exist.") 
        return $false    
    }

    [bool] VerifyModule()
    {
        $modules = Get-Module -Name $this.Name -ListAvailable
        if ($modules)
        {
            if ($this.RequiredVersion -in $modules.version)
            {
                Write-Verbose "Found the correct module version: $($this.RequiredVersion)"
                return $true
            }
            else
            {
                AddTrace("The required version ($($this.RequiredVersion)) is not available on this host.")
            }
        }
        else
        {
            AddTrace("The PowerShell Module ($($this.Name)) is not available on system.")
        }
        return $false    
    }

    [bool] VerifyParams()
    {
        if ($this.VerifyPsRepo() -and $this.VerifyModule())
        {
            Write-Verbose "PsRepo and Module verfied."
            return $true
        }
        else 
        {
            Write-Error $this.ErrorTrace
            return $false
        }
    }

    [System.Collections.Hashtable] CollectParams(
        [ValidateSet('Find', 'All')] 
        [String] $ParamSet
    )
    {
        $params = @{
            Name = $this.Name
            Repository = $this.PSRepository
        }
        if ($this.RequiredVersion)  { $params.Add('RequiredVersion', $this.RequiredVersion) }
        if ($ParamSet -eq 'Find')   { return $params }

        if ($this.NuGetApiKey)      { $params.Add('NuGetApiKey', $this.NuGetApiKey) }
        if ($this.ProjectUri)       { $params.Add('ProjectUri', $this.ProjectUri) }
        if ($this.FormatVersion)    { $params.Add('FormatVersion', $this.FormatVersion) }
        if ($this.ReleaseNotes)     { $params.Add('ReleaseNotes', $this.ReleaseNotes) }
        if ($this.Tags)             { $params.Add('Tags', $this.Tags) }
        if ($this.LicenseUri)       { $params.Add('LicenseUri', $this.LicenseUri) }
        if ($this.IconUri)          { $params.Add('IconUri', $this.IconUri) }
        return $params
    }

}