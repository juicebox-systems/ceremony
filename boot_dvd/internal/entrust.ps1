# This script is run from Windows to copy files from the vendor DVD.

$files=@(
    [pscustomobject]@{
        path='E:\CODESAFE.ZIP'
        hash='7D6EAFF0548D90143D35834F1EA1CF092321E9003E10E14895A01A6F412ADADB'
    },
    [pscustomobject]@{
        path='E:\FIRMWARE.ZIP'
        hash='035DD8B9841D965C8F048C357AB25E1BF7C11AFAA5D616482F1B2A1F8590FDC8'
    },
    [pscustomobject]@{
        path='E:\SECWORLD.ZIP'
        hash='D05E958B19B26AC4B984CC8E5950C8BAA1CD72F1EFB7EDE2141317B130CB89E7'
    }
)

foreach ($expected in $files) {
    $actual = Get-FileHash $expected.path
    echo $actual
    if ($actual.hash -eq $expected.hash) {
        Copy-Item -Path $expected.path -Destination 'C:\Users\defaultuser0\' -Force -Verbose
    } else {
        throw "Invalid hash for " + $expected.path
    }
}
