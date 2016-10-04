using module ..\..\cPackageManagement.psm1

$r = [cPSRepository]::new()

Describe 'cPSRepository' {
    Context 'defaults with only name' {
        $r.Test() | Should Be $false
    }
}

