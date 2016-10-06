using module ..\..\cPackageManagement.psm1

$r = [cPSRepository]::new()

Describe 'cPSRepository' {
    Context 'No properites given' {
        $r.Test() | Should Be throw
    }
}

