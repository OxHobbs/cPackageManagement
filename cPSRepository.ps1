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
                Write-Verbose "PS Respository named $($this.Name) is registered but has some incorrect settings."
                return $false
            }
            Write-Verbose "PS Repository is already existent with the correct properties.  Will return true"
            return $true
        }
        else
        {
            Write-Verbose "Ensue is set to Absent"
            if (-not $repo) { return $true }
            return $false
        }

    }

    [void] Set()
    {
        Write-Verbose "Running Set Method"

        $repo = Get-PsRepository -Name $this.Name -ErrorAction SilentlyContinue

        if ($this.Ensure -eq 'Present')
        {
            $params = @{
                Name                      = $this.Name
                SourceLocation            = $this.SourceLocation
                PublishLocation           = $this.PublishLocation
                InstallationPolicy        = $this.InstallationPolicy
                PackageManagementProvider = $this.PackageManagementProvider
            }

            if ($this.ScriptPublishLocation) 
            { 
                Write-Verbose "Adding Publish Location"
                $params.Add('ScriptPublishLocation', $this.ScriptPublishLocation) 
            }
            if ($this.ScriptSourceLocation)  
            { 
                Write-Verbose "Adding Source Location"
                $params.Add('ScriptSourceLocation', $this.ScriptSourceLocation) 
            }

            if ($repo)
            {
                Write-Verbose "The repo exists, will use set-psrepository to correct incorrect settings."
                Write-Verbose "Will set the repo to use the following settings: $params"
                Write-Verbose "The InstallationPolicy is set to: $($this.InstallationPolicy)"
                Set-PsRepository @params
            }
            else 
            {
                Write-Verbose "The repo will be registered"
                Register-PSRepository @params
            }
        }
        else
        {
            Unregister-PSRepository -Name $this.Name 
        }
    }
}