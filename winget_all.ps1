
Write-Output "The script will now install all your apps. Feel free to grab a coffee or keep working on something else!"

$apps = @(
    @{name = "Mozilla.Firefox.ESR" },
    @{name = "qBittorrent.qBittorrent" },
    @{name = "PeterPawlowski.foobar2000" },
    @{name = "PeterPawlowski.foobar2000.EncoderPack" },
	@{name = "FlorianHeidenreich.Mp3tag" },
	@{name = "Sony.MusicCenter" },
    @{name = "AndreWiethoff.ExactAudioCopy" },
    @{name = "LIGHTNINGUK.ImgBurn" },
    @{name = "CodecGuide.K-LiteCodecPack.Standard" },
    @{name = "clsid2.mpc-hc" }
	@{name = "IrfanSkiljan.IrfanView" },
    @{name = "IrfanSkiljan.IrfanView.PlugIns" },
	@{name = "calibre.calibre" },
    @{name = "Sigil-Ebook.Sigil" },
    @{name = "Notepad++.Notepad++" },
    @{name = "SumatraPDF.SumatraPDF" },
    @{name = "7zip.7zip" }
);

Foreach ($app in $apps) {
    $listApp = winget list --exact -q $app.name
    if (![String]::Join("", $listApp).Contains($app.name)) {
        Write-host "Installing" $app.name
        winget install -e -h --accept-source-agreements --accept-package-agreements --id $app.name 
    }
    else {
        Write-host "Skipping" $app.name "(app already installed)"
    }
}