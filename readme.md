# cPackageManagement DSC Resource

## Resources

### cPSRepository

This resource allows you to register/unregister a PowerShell Repository on a system.  Note that the PSGallery PowerShell Repository is built-in and cannot be removed.
* **Name**: (Key, Required) The name of the PowerShell Repository to register/unregister.
* **Ensure**: Indicates if the PoSh Repo should be registered or unregistered. Defaults to 'Present'
* **SourceLocation**: (Required) The URI of the PowerShell Repository from which to access modules.
* **PublishLocation**: The URI of the PowerShell Repository to be used for publishing modules.
* **ScriptSourceLocation**: URI location for Script Source.
* **ScriptPublishLocation**: URI location for Script Publish.
* **InstallationPolicy**: Specify whether the repository is trusted or untrusted { `'Trusted'` | `'Untrusted'` }.  Defaults to 'Untrusted'
* **PackageManagementProvider**: Specify the provider to use for interfacing with the respository.  Defaults to 'NuGet'

## Change Log
### v0.1.0
* Added the cPSRepository resource.  This is the single resource in this version