# ============================================================
# DOGGO EMO CHAOS PRANK
#
# Fisiere in acelasi folder:
#   prank.ps1
#   imagine.jpg
#   latrat.mp3
#
# Face:
# - imagine.jpg -> wallpaper pentru sesiunea curenta
# - Windows master volume -> 70%
# - latrat random la 1-10 secunde
# - 25% sansa de double bark la latratul random
# - popup-uri cu imaginea dark
# - imagine oglindita / intoarsa / rotita random
# - 20% sansa ca un popup sa fie FULLSCREEN
# - fullscreen-ul incearca sa ia focus
# - fullscreen = double bark
# - fullscreen-ul continua sa roteasca imaginea random
# - maxim 25 ferestre simultan
#
# Nu exista timer de oprire si nu exista ESC.
# ============================================================


# ============================================================
# CONFIG
# ============================================================

$WINDOWS_VOLUME = 0.86

$MAX_WINDOWS = 25

$MIN_BARK_SECONDS = 1
$MAX_BARK_SECONDS = 10

$DOUBLE_RANDOM_BARK_CHANCE = 25

$MIN_POPUP_MS = 300
$MAX_POPUP_MS = 1700

$BIG_WINDOW_CHANCE = 20

# Cat de repede se intoarce poza in fullscreen
$MIN_FLIP_MS = 350
$MAX_FLIP_MS = 900

# Cat de intunecata sa fie poza
# 0.15 = foarte dark
# 0.30 = dark
# 0.50 = mai vizibila
$DARK_LEVEL = 0.28


# ============================================================
# LIBRARIES
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


# ============================================================
# FILE PATHS
# ============================================================

$BasePath = Split-Path -Parent $MyInvocation.MyCommand.Path

$ImagePath = Join-Path $BasePath "imagine.jpg"
$AudioPath = Join-Path $BasePath "latrat.mp3"


if (!(Test-Path $ImagePath)) {

    [System.Windows.Forms.MessageBox]::Show(
        "Nu gasesc imagine.jpg in folderul scriptului."
    )

    exit
}


if (!(Test-Path $AudioPath)) {

    [System.Windows.Forms.MessageBox]::Show(
        "Nu gasesc latrat.mp3 in folderul scriptului."
    )

    exit
}


# ============================================================
# RANDOM
# ============================================================

$Random = New-Object System.Random


# ============================================================
# WALLPAPER API
# ============================================================

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class PrankWallpaper
{
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(
        int uAction,
        int uParam,
        string lpvParam,
        int fuWinIni
    );
}
"@


# Fill
Set-ItemProperty `
    "HKCU:\Control Panel\Desktop" `
    -Name WallpaperStyle `
    -Value "10"

Set-ItemProperty `
    "HKCU:\Control Panel\Desktop" `
    -Name TileWallpaper `
    -Value "0"


# 20 = SPI_SETDESKWALLPAPER
#
# fuWinIni = 0
# Nu cerem salvarea wallpaper-ului in profilul Windows.
[PrankWallpaper]::SystemParametersInfo(
    20,
    0,
    $ImagePath,
    0
) | Out-Null


# ============================================================
# WINDOWS MASTER AUDIO API
# ============================================================

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

[Guid("5CDF2C82-841E-4546-9722-0CF74078229A")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IAudioEndpointVolume
{
    int RegisterControlChangeNotify(IntPtr pNotify);
    int UnregisterControlChangeNotify(IntPtr pNotify);

    int GetChannelCount(
        out uint channelCount
    );

    int SetMasterVolumeLevel(
        float level,
        Guid eventContext
    );

    int SetMasterVolumeLevelScalar(
        float level,
        Guid eventContext
    );

    int GetMasterVolumeLevel(
        out float level
    );

    int GetMasterVolumeLevelScalar(
        out float level
    );

    int SetChannelVolumeLevel(
        uint channelNumber,
        float level,
        Guid eventContext
    );

    int SetChannelVolumeLevelScalar(
        uint channelNumber,
        float level,
        Guid eventContext
    );

    int GetChannelVolumeLevel(
        uint channelNumber,
        out float level
    );

    int GetChannelVolumeLevelScalar(
        uint channelNumber,
        out float level
    );

    int SetMute(
        [MarshalAs(UnmanagedType.Bool)] bool isMuted,
        Guid eventContext
    );

    int GetMute(
        out bool isMuted
    );

    int GetVolumeStepInfo(
        out uint step,
        out uint stepCount
    );

    int VolumeStepUp(
        Guid eventContext
    );

    int VolumeStepDown(
        Guid eventContext
    );

    int QueryHardwareSupport(
        out uint hardwareSupportMask
    );

    int GetVolumeRange(
        out float min,
        out float max,
        out float increment
    );
}


[Guid("D666063F-1587-4E43-81F1-B948E807363F")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IMMDevice
{
    int Activate(
        ref Guid iid,
        int clsCtx,
        IntPtr activationParams,
        out IAudioEndpointVolume endpointVolume
    );
}


[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IMMDeviceEnumerator
{
    int EnumAudioEndpoints(
        int dataFlow,
        int stateMask,
        IntPtr devices
    );

    int GetDefaultAudioEndpoint(
        int dataFlow,
        int role,
        out IMMDevice device
    );
}


[ComImport]
[Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
public class MMDeviceEnumerator
{
}


public static class PrankAudio
{
    public static void SetVolume(float level)
    {
        IMMDeviceEnumerator enumerator =
            (IMMDeviceEnumerator)new MMDeviceEnumerator();

        IMMDevice device;

        enumerator.GetDefaultAudioEndpoint(
            0,
            1,
            out device
        );

        Guid iid =
            typeof(IAudioEndpointVolume).GUID;

        IAudioEndpointVolume endpoint;

        device.Activate(
            ref iid,
            23,
            IntPtr.Zero,
            out endpoint
        );

        endpoint.SetMute(
            false,
            Guid.Empty
        );

        endpoint.SetMasterVolumeLevelScalar(
            level,
            Guid.Empty
        );
    }
}
"@


function Set-PrankVolume {

    try {

        [PrankAudio]::SetVolume(
            [single]$WINDOWS_VOLUME
        )

    }
    catch {}
}


# Pune Windows la 70% imediat
Set-PrankVolume


# ============================================================
# AUDIO PLAYER
# ============================================================

try {

    $Player = New-Object -ComObject WMPlayer.OCX

    # Player-ul are 100%, dar Windows master este 70%.
    $Player.settings.volume = 100

    $Player.settings.autoStart = $false

}
catch {

    [System.Windows.Forms.MessageBox]::Show(
        "Nu pot initializa Windows Media Player pentru MP3."
    )

    exit
}


function Play-Bark {

    try {

        # Daca volumul a fost schimbat intre timp,
        # il pune din nou la 70%.
        Set-PrankVolume

        $Player.controls.stop()

        $Player.URL = $AudioPath

        $Player.controls.currentPosition = 0

        $Player.controls.play()

    }
    catch {}
}


function Play-DoubleBark {

    Play-Bark

    Start-Sleep -Milliseconds 700

    Play-Bark
}


# ============================================================
# LOAD IMAGE
# ============================================================

$OriginalImage =
    [System.Drawing.Image]::FromFile(
        $ImagePath
    )


# ============================================================
# CREATE DARK / EMO VERSION
# ============================================================

function New-EmoImage {

    param(
        [System.Drawing.Image]$Source
    )


    $Bitmap =
        New-Object System.Drawing.Bitmap(
            $Source.Width,
            $Source.Height
        )


    $Graphics =
        [System.Drawing.Graphics]::FromImage(
            $Bitmap
        )


    # -----------------------------
    # DARK COLOR MATRIX
    # -----------------------------

    $Matrix =
        New-Object System.Drawing.Imaging.ColorMatrix


    $Matrix.Matrix00 = $DARK_LEVEL
    $Matrix.Matrix11 = $DARK_LEVEL
    $Matrix.Matrix22 = $DARK_LEVEL

    $Matrix.Matrix33 = 1.0
    $Matrix.Matrix44 = 1.0


    $Attributes =
        New-Object System.Drawing.Imaging.ImageAttributes


    $Attributes.SetColorMatrix(
        $Matrix
    )


    $Rectangle =
        New-Object System.Drawing.Rectangle(
            0,
            0,
            $Source.Width,
            $Source.Height
        )


    $Graphics.DrawImage(
        $Source,
        $Rectangle,
        0,
        0,
        $Source.Width,
        $Source.Height,
        [System.Drawing.GraphicsUnit]::Pixel,
        $Attributes
    )


    # -----------------------------
    # EXTRA BLACK OVERLAY
    # -----------------------------

    $BlackBrush =
        New-Object System.Drawing.SolidBrush(
            [System.Drawing.Color]::FromArgb(
                45,
                0,
                0,
                0
            )
        )


    $Graphics.FillRectangle(
        $BlackBrush,
        0,
        0,
        $Bitmap.Width,
        $Bitmap.Height
    )


    $BlackBrush.Dispose()
    $Attributes.Dispose()
    $Graphics.Dispose()


    return $Bitmap
}


$EmoBaseImage =
    New-EmoImage $OriginalImage


# ============================================================
# WINDOW STORAGE
# ============================================================

$Windows =
    New-Object System.Collections.ArrayList


# ============================================================
# RANDOM IMAGE ROTATION
# ============================================================

function Invoke-RandomFlip {

    param(
        [System.Drawing.Image]$TargetImage
    )


    $Mode = $Random.Next(0, 8)


    switch ($Mode) {

        0 {
            # normal
        }


        1 {

            $TargetImage.RotateFlip(
                [System.Drawing.RotateFlipType]::RotateNoneFlipX
            )

        }


        2 {

            $TargetImage.RotateFlip(
                [System.Drawing.RotateFlipType]::RotateNoneFlipY
            )

        }


        3 {

            $TargetImage.RotateFlip(
                [System.Drawing.RotateFlipType]::Rotate180FlipNone
            )

        }


        4 {

            $TargetImage.RotateFlip(
                [System.Drawing.RotateFlipType]::Rotate180FlipX
            )

        }


        5 {

            $TargetImage.RotateFlip(
                [System.Drawing.RotateFlipType]::Rotate90FlipX
            )

        }


        6 {

            $TargetImage.RotateFlip(
                [System.Drawing.RotateFlipType]::Rotate270FlipX
            )

        }


        7 {

            $TargetImage.RotateFlip(
                [System.Drawing.RotateFlipType]::Rotate180FlipY
            )

        }
    }
}


# ============================================================
# CLEAN OLD WINDOWS
# ============================================================

function Clear-DeadWindows {

    for (
        $i = $Windows.Count - 1;
        $i -ge 0;
        $i--
    ) {

        try {

            if (
                $Windows[$i] -eq $null -or
                $Windows[$i].IsDisposed
            ) {

                $Windows.RemoveAt($i)

            }

        }
        catch {

            $Windows.RemoveAt($i)

        }
    }
}


# ============================================================
# CREATE POPUP
# ============================================================

function New-ScaryWindow {

    Clear-DeadWindows


    # ========================================================
    # LIMIT NUMBER OF WINDOWS
    # ========================================================

    if ($Windows.Count -ge $MAX_WINDOWS) {

        $OldWindow = $Windows[0]

        try {

            if (
                $OldWindow -and
                !$OldWindow.IsDisposed
            ) {

                $OldWindow.Close()
                $OldWindow.Dispose()

            }

        }
        catch {}


        $Windows.RemoveAt(0)
    }


    # ========================================================
    # PICK RANDOM MONITOR
    # ========================================================

    $Screens =
        [System.Windows.Forms.Screen]::AllScreens


    $Screen =
        $Screens[
            $Random.Next(
                0,
                $Screens.Count
            )
        ]


    # ========================================================
    # FORM
    # ========================================================

    $Form =
        New-Object System.Windows.Forms.Form


    $Form.FormBorderStyle =
        [System.Windows.Forms.FormBorderStyle]::None


    $Form.ShowInTaskbar = $false

    $Form.TopMost = $true


    $Form.BackColor =
        [System.Drawing.Color]::Black


    # ========================================================
    # PICTURE
    # ========================================================

    $Picture =
        New-Object System.Windows.Forms.PictureBox


    $Picture.Dock =
        [System.Windows.Forms.DockStyle]::Fill


    $Picture.SizeMode =
        [System.Windows.Forms.PictureBoxSizeMode]::Zoom


    $Picture.BackColor =
        [System.Drawing.Color]::Black


    # Fiecare popup primeste propria copie
    $PopupImage =
        $EmoBaseImage.Clone()


    # Pozitie initiala random
    Invoke-RandomFlip $PopupImage


    $Picture.Image =
        $PopupImage


    $Form.Controls.Add(
        $Picture
    )


    # ========================================================
    # SAVE DATA FOR CLEANUP
    # ========================================================

    $Form.Tag =
        [PSCustomObject]@{

            Image = $PopupImage

            Timer = $null

        }


    # ========================================================
    # CLEANUP WHEN WINDOW CLOSES
    # ========================================================

    $Form.Add_FormClosed({

        param(
            $sender,
            $eventArgs
        )


        try {

            if (
                $sender.Tag.Timer -ne $null
            ) {

                $sender.Tag.Timer.Stop()

                $sender.Tag.Timer.Dispose()

            }

        }
        catch {}


        try {

            if (
                $sender.Tag.Image -ne $null
            ) {

                $sender.Tag.Image.Dispose()

            }

        }
        catch {}

    })


    # ========================================================
    # BIG SCARY CHECK
    # ========================================================

    $IsBigScary =
        (
            $Random.Next(1, 101) -le
            $BIG_WINDOW_CHANCE
        )


    # ========================================================
    # 20% = FULLSCREEN MODE
    # ========================================================

    if ($IsBigScary) {

        $Form.StartPosition =
            [System.Windows.Forms.FormStartPosition]::Manual


        # Tot monitorul ales
        $Form.Bounds =
            $Screen.Bounds


        [void]$Windows.Add(
            $Form
        )


        $Form.Show()


        # ----------------------------------------
        # TRY TO TAKE FOCUS
        # ----------------------------------------

        try {

            $Form.TopMost = $true

            $Form.BringToFront()

            $Form.Activate()

            $Form.Focus()

        }
        catch {}


        [System.Windows.Forms.Application]::DoEvents()


        # ----------------------------------------
        # DOUBLE BARK
        # ----------------------------------------

        Play-DoubleBark


        # ----------------------------------------
        # RANDOM FLIP TIMER
        # ----------------------------------------

        $FlipTimer =
            New-Object System.Windows.Forms.Timer


        $FlipTimer.Interval =
            $Random.Next(
                $MIN_FLIP_MS,
                $MAX_FLIP_MS + 1
            )


        $Form.Tag.Timer =
            $FlipTimer


        $CapturedForm = $Form
        $CapturedPicture = $Picture


        $FlipHandler = {

            try {

                if (
                    !$CapturedForm.IsDisposed -and
                    $CapturedPicture.Image -ne $null
                ) {

                    Invoke-RandomFlip `
                        $CapturedPicture.Image


                    $CapturedPicture.Refresh()


                    # fiecare flip primeste alt delay
                    $this.Interval =
                        $Random.Next(
                            $MIN_FLIP_MS,
                            $MAX_FLIP_MS + 1
                        )

                }

            }
            catch {}

        }.GetNewClosure()


        $FlipTimer.Add_Tick(
            $FlipHandler
        )


        $FlipTimer.Start()

    }


    # ========================================================
    # NORMAL RANDOM WINDOW
    # ========================================================

    else {

        $Width =
            $Random.Next(
                180,
                651
            )


        $Height =
            $Random.Next(
                150,
                501
            )


        $Form.Width = $Width
        $Form.Height = $Height


        $MinX =
            $Screen.Bounds.Left


        $MinY =
            $Screen.Bounds.Top


        $MaxX =
            [Math]::Max(
                $MinX + 1,
                $Screen.Bounds.Right - $Width
            )


        $MaxY =
            [Math]::Max(
                $MinY + 1,
                $Screen.Bounds.Bottom - $Height
            )


        $Form.StartPosition =
            [System.Windows.Forms.FormStartPosition]::Manual


        $X =
            $Random.Next(
                $MinX,
                $MaxX
            )


        $Y =
            $Random.Next(
                $MinY,
                $MaxY
            )


        $Form.Location =
            New-Object System.Drawing.Point(
                $X,
                $Y
            )


        [void]$Windows.Add(
            $Form
        )


        $Form.Show()
    }
}


# ============================================================
# INITIAL RANDOM TIMES
# ============================================================

$NextBark =
    (Get-Date).AddSeconds(
        $Random.Next(
            $MIN_BARK_SECONDS,
            $MAX_BARK_SECONDS + 1
        )
    )


$NextPopup =
    (Get-Date).AddMilliseconds(
        $Random.Next(
            $MIN_POPUP_MS,
            $MAX_POPUP_MS + 1
        )
    )


# ============================================================
# MAIN LOOP
#
# Continua cat timp procesul PowerShell exista.
# ============================================================

while ($true) {

    $Now = Get-Date


    # ========================================================
    # RANDOM BARK
    # ========================================================

    if ($Now -ge $NextBark) {


        # 25% sansa de double bark
        if (
            $Random.Next(1, 101) -le
            $DOUBLE_RANDOM_BARK_CHANCE
        ) {

            Play-DoubleBark

        }

        else {

            Play-Bark

        }


        $NextBark =
            (Get-Date).AddSeconds(
                $Random.Next(
                    $MIN_BARK_SECONDS,
                    $MAX_BARK_SECONDS + 1
                )
            )
    }


    # ========================================================
    # RANDOM POPUP
    # ========================================================

    if ($Now -ge $NextPopup) {


        New-ScaryWindow


        $NextPopup =
            (Get-Date).AddMilliseconds(
                $Random.Next(
                    $MIN_POPUP_MS,
                    $MAX_POPUP_MS + 1
                )
            )
    }


    # ========================================================
    # KEEP WINFORMS ALIVE
    # ========================================================

    [System.Windows.Forms.Application]::DoEvents()

    Start-Sleep -Milliseconds 25
}