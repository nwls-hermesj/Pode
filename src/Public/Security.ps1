<#
.SYNOPSIS
Sets inbuilt definitions for security headers.

.DESCRIPTION
Sets inbuilt definitions for security headers, in either Simple or Strict types.

.PARAMETER Type
The Type of security to use.

.PARAMETER UseHsts
If supplied, the Strict-Transport-Security header will be set.

.PARAMETER XssBlock
If supplied, the X-XSS-Protection header will be set to blocking mode. (Default: Off)

.PARAMETER CspReportOnly
If supplied, the Content-Security-Policy header will be set as the Content-Security-Policy-Report-Only header.

.EXAMPLE
Set-PodeSecurity -Type Simple

.EXAMPLE
Set-PodeSecurity -Type Strict -UseHsts
#>
function Set-PodeSecurity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Simple', 'Strict')]
        [string]
        $Type,

        [switch]
        $UseHsts,

        [switch]
        $XssBlock,

        [switch]
        $CspReportOnly
    )

    # general headers
    Set-PodeSecurityContentTypeOptions

    Set-PodeSecurityPermissionsPolicy `
        -SyncXhr 'none' `
        -Fullscreen 'self' `
        -Camera 'none' `
        -Geolocation 'self' `
        -PictureInPicture 'self' `
        -Accelerometer 'none' `
        -Microphone 'none' `
        -Usb 'none' `
        -Autoplay 'self' `
        -Payment 'none' `
        -Magnetometer 'self' `
        -Gyroscope 'self' `
        -DisplayCapture 'self'

    Set-PodeSecurityCrossOrigin -Embed Require-Corp -Open Same-Origin -Resource Same-Origin
    Set-PodeSecurityAccessControl -Origin '*' -Methods '*' -Headers '*' -Duration 7200
    Set-PodeSecurityContentSecurityPolicy -Default 'self' -XssBlock:$XssBlock -ReportOnly:$CspReportOnly

    # only add hsts if specifiec
    if ($UseHsts) {
        Set-PodeSecurityStrictTransportSecurity -Duration 31536000 -IncludeSubDomains
    }

    # type specific headers
    switch ($Type.ToLowerInvariant()) {
        'simple' {
            Set-PodeSecurityFrameOptions -Type SameOrigin
            Set-PodeSecurityReferrerPolicy -Type Strict-Origin
        }

        'strict' {
            Set-PodeSecurityFrameOptions -Type Deny
            Set-PodeSecurityReferrerPolicy -Type No-Referrer
        }
    }

    # hide server info
    Hide-PodeSecurityServer
}

<#
.SYNOPSIS
Removes definitions for all security headers.

.DESCRIPTION
Removes definitions for all security headers.

.EXAMPLE
Remove-PodeSecurity
#>
function Remove-PodeSecurity {
    [CmdletBinding()]
    param()

    $PodeContext.Server.Security.Headers.Clear()
    Show-PodeSecurityServer
}

<#
.SYNOPSIS
Add definition for specified security header.

.DESCRIPTION
Add definition for specified security header.

.PARAMETER Name
The Name of the security header.

.PARAMETER Value
The Value of the security header.

.PARAMETER Append
Append the value to the header instead of replacing it

.EXAMPLE
Add-PodeSecurityHeader -Name 'X-Header-Name' -Value 'SomeValue'
#>
function Add-PodeSecurityHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Value,

        [Parameter()]
        [switch]
        $Append
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    if ($Append -and $PodeContext.Server.Security.Headers.ContainsKey($Name)) {
        $Headers = @(($PodeContext.Server.Security.Headers[$Name].split(',')).trim())
        if ($Headers -inotcontains $Value) {
            $Headers += $Value
            $PodeContext.Server.Security.Headers[$Name] = (($Headers.trim() | Select-Object -Unique) -join ', ')
        }
        else {
            return
        }
    }
    else {
        $PodeContext.Server.Security.Headers[$Name] = $Value
    }
}

<#
.SYNOPSIS
Removes definition for specified security header.

.DESCRIPTION
Removes definition for specified security header.

.PARAMETER Name
The Name of the security header.

.EXAMPLE
Remove-PodeSecurityHeader -Name 'X-Header-Name'
#>
function Remove-PodeSecurityHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Name
    )

    $PodeContext.Server.Security.Headers.Remove($Name)
}

<#
.SYNOPSIS
Hide the Server HTTP Header from Responses

.DESCRIPTION
Hide the Server HTTP Header from Responses

.EXAMPLE
Hide-PodeSecurityServer
#>
function Hide-PodeSecurityServer {
    [CmdletBinding()]
    param()

    $PodeContext.Server.Security.ServerDetails = $false
}

<#
.SYNOPSIS
Show the Server HTTP Header on Responses

.DESCRIPTION
Show the Server HTTP Header on Responses

.EXAMPLE
Show-PodeSecurityServer
#>
function Show-PodeSecurityServer {
    [CmdletBinding()]
    param()

    $PodeContext.Server.Security.ServerDetails = $true
}

<#
.SYNOPSIS
Set a value for the X-Frame-Options header.

.DESCRIPTION
Set a value for the X-Frame-Options header.

.PARAMETER Type
The Type to use.

.EXAMPLE
Set-PodeSecurityFrameOptions -Type SameOrigin
#>
function Set-PodeSecurityFrameOptions {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Deny', 'SameOrigin')]
        [string]
        $Type
    )

    Add-PodeSecurityHeader -Name 'X-Frame-Options' -Value $Type.ToUpperInvariant()
}

<#
.SYNOPSIS
Removes definition for the X-Frame-Options header.

.DESCRIPTION
Removes definition for the X-Frame-Options header.

.EXAMPLE
Remove-PodeSecurityFrameOptions
#>
function Remove-PodeSecurityFrameOptions {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    param()

    Remove-PodeSecurityHeader -Name 'X-Frame-Options'
}

<#
.SYNOPSIS
Set the value to use for the Content-Security-Policy and X-XSS-Protection headers.

.DESCRIPTION
Set the value to use for the Content-Security-Policy and X-XSS-Protection headers.

.PARAMETER Default
The values to use for the Default portion of the header.

.PARAMETER Child
The values to use for the Child portion of the header.

.PARAMETER Connect
The values to use for the Connect portion of the header.

.PARAMETER Font
The values to use for the Font portion of the header.

.PARAMETER Frame
The values to use for the Frame portion of the header.

.PARAMETER Image
The values to use for the Image portion of the header.

.PARAMETER Manifest
The values to use for the Manifest portion of the header.

.PARAMETER Media
The values to use for the Media portion of the header.

.PARAMETER Object
The values to use for the Object portion of the header.

.PARAMETER Scripts
The values to use for the Scripts portion of the header.

.PARAMETER Style
The values to use for the Style portion of the header.

.PARAMETER BaseUri
The values to use for the BaseUri portion of the header.

.PARAMETER FormAction
The values to use for the FormAction portion of the header.

.PARAMETER FrameAncestor
The values to use for the FrameAncestor portion of the header.

.PARAMETER FencedFrame
The values to use for the FencedFrame portion of the header.

.PARAMETER Prefetch
The values to use for the Prefetch portion of the header.

.PARAMETER ScriptAttr
The values to use for the ScriptAttr portion of the header.

.PARAMETER ScriptElem
The values to use for the ScriptElem portion of the header.

.PARAMETER StyleAttr
The values to use for the StyleAttr portion of the header.

.PARAMETER StyleElem
The values to use for the StyleElem portion of the header.

.PARAMETER Worker
The values to use for the Worker portion of the header.

.PARAMETER Sandbox
The value to use for the Sandbox portion of the header.

.PARAMETER ReportUri
The value to use for the ReportUri portion of the header.

.PARAMETER UpgradeInsecureRequests
If supplied, the header will have the upgrade-insecure-requests value added.

.PARAMETER XssBlock
If supplied, the X-XSS-Protection header will be set to blocking mode. (Default: Off)

.PARAMETER ReportOnly
If supplied, the header will be set as a report-only header.

.EXAMPLE
Set-PodeSecurityContentSecurityPolicy -Default 'self'
#>
function Set-PodeSecurityContentSecurityPolicy {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]
        $Default,

        [Parameter()]
        [string[]]
        $Child,

        [Parameter()]
        [string[]]
        $Connect,

        [Parameter()]
        [string[]]
        $Font,

        [Parameter()]
        [string[]]
        $Frame,

        [Parameter()]
        [string[]]
        $Image,

        [Parameter()]
        [string[]]
        $Manifest,

        [Parameter()]
        [string[]]
        $Media,

        [Parameter()]
        [string[]]
        $Object,

        [Parameter()]
        [string[]]
        $Scripts,

        [Parameter()]
        [string[]]
        $Style,

        [Parameter()]
        [string[]]
        $BaseUri,

        [Parameter()]
        [string[]]
        $FormAction,

        [Parameter()]
        [string[]]
        $FrameAncestor,

        [Parameter()]
        [string[]]
        $FencedFrame,

        [Parameter()]
        [string[]]
        $Prefetch,

        [Parameter()]
        [string[]]
        $ScriptAttr,

        [Parameter()]
        [string[]]
        $ScriptElem,

        [Parameter()]
        [string[]]
        $StyleAttr,

        [Parameter()]
        [string[]]
        $StyleElem,

        [Parameter()]
        [string[]]
        $Worker,

        [Parameter()]
        [ValidateSet('', 'Allow-Downloads', 'Allow-Downloads-Without-User-Activation', 'Allow-Forms', 'Allow-Modals', 'Allow-Orientation-Lock',
            'Allow-Pointer-Lock', 'Allow-Popups', 'Allow-Popups-To-Escape-Sandbox', 'Allow-Presentation', 'Allow-Same-Origin', 'Allow-Scripts',
            'Allow-Storage-Access-By-User-Activation', 'Allow-Top-Navigation', 'Allow-Top-Navigation-By-User-Activation', 'None')]
        [string]
        $Sandbox = 'None',

        [Parameter()]
        [string]
        $ReportUri,

        [switch]
        $UpgradeInsecureRequests,

        [switch]
        $XssBlock,

        [switch]
        $ReportOnly
    )

    Set-PodeSecurityContentSecurityPolicyInternal -Params $PSBoundParameters
}

<#
.SYNOPSIS
Adds additional values to already defined values for the Content-Security-Policy header.

.DESCRIPTION
Adds additional values to already defined values for the Content-Security-Policy header, instead of overriding them.

.PARAMETER Default
The values to add for the Default portion of the header.

.PARAMETER Child
The values to add for the Child portion of the header.

.PARAMETER Connect
The values to add for the Connect portion of the header.

.PARAMETER Font
The values to add for the Font portion of the header.

.PARAMETER Frame
The values to add for the Frame portion of the header.

.PARAMETER Image
The values to add for the Image portion of the header.

.PARAMETER Manifest
The values to add for the Manifest portion of the header.

.PARAMETER Media
The values to add for the Media portion of the header.

.PARAMETER Object
The values to add for the Object portion of the header.

.PARAMETER Scripts
The values to add for the Scripts portion of the header.

.PARAMETER Style
The values to add for the Style portion of the header.

.PARAMETER BaseUri
The values to add for the BaseUri portion of the header.

.PARAMETER FormAction
The values to add for the FormAction portion of the header.

.PARAMETER FrameAncestor
The values to add for the FrameAncestor portion of the header.

.PARAMETER FencedFrame
The values to add for the FencedFrame portion of the header.

.PARAMETER Prefetch
The values to add for the Prefetch portion of the header.

.PARAMETER ScriptAttr
The values to add for the ScriptAttr portion of the header.

.PARAMETER ScriptElem
The values to add for the ScriptElem portion of the header.

.PARAMETER StyleAttr
The values to add for the StyleAttr portion of the header.

.PARAMETER StyleElem
The values to add for the StyleElem portion of the header.

.PARAMETER Worker
The values to add for the Worker portion of the header.

.PARAMETER Sandbox
The value to use for the Sandbox portion of the header.

.PARAMETER ReportUri
The value to use for the ReportUri portion of the header.

.PARAMETER UpgradeInsecureRequests
If supplied, the header will have the upgrade-insecure-requests value added.

.PARAMETER ReportOnly
If supplied, the header will be set as a report-only header.

.EXAMPLE
Add-PodeSecurityContentSecurityPolicy -Default '*.twitter.com' -Image 'data'
#>
function Add-PodeSecurityContentSecurityPolicy {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]
        $Default,

        [Parameter()]
        [string[]]
        $Child,

        [Parameter()]
        [string[]]
        $Connect,

        [Parameter()]
        [string[]]
        $Font,

        [Parameter()]
        [string[]]
        $Frame,

        [Parameter()]
        [string[]]
        $Image,

        [Parameter()]
        [string[]]
        $Manifest,

        [Parameter()]
        [string[]]
        $Media,

        [Parameter()]
        [string[]]
        $Object,

        [Parameter()]
        [string[]]
        $Scripts,

        [Parameter()]
        [string[]]
        $Style,

        [Parameter()]
        [string[]]
        $BaseUri,

        [Parameter()]
        [string[]]
        $FormAction,

        [Parameter()]
        [string[]]
        $FrameAncestor,

        [Parameter()]
        [string[]]
        $FencedFrame,

        [Parameter()]
        [string[]]
        $Prefetch,

        [Parameter()]
        [string[]]
        $ScriptAttr,

        [Parameter()]
        [string[]]
        $ScriptElem,

        [Parameter()]
        [string[]]
        $StyleAttr,

        [Parameter()]
        [string[]]
        $StyleElem,

        [Parameter()]
        [string[]]
        $Worker,

        [Parameter()]
        [ValidateSet('', 'Allow-Downloads', 'Allow-Downloads-Without-User-Activation', 'Allow-Forms', 'Allow-Modals', 'Allow-Orientation-Lock',
            'Allow-Pointer-Lock', 'Allow-Popups', 'Allow-Popups-To-Escape-Sandbox', 'Allow-Presentation', 'Allow-Same-Origin', 'Allow-Scripts',
            'Allow-Storage-Access-By-User-Activation', 'Allow-Top-Navigation', 'Allow-Top-Navigation-By-User-Activation', 'None')]
        [string]
        $Sandbox = 'None',

        [Parameter()]
        [string]
        $ReportUri,

        [switch]
        $UpgradeInsecureRequests,

        [switch]
        $ReportOnly
    )

    Set-PodeSecurityContentSecurityPolicyInternal -Params $PSBoundParameters -Append
}

<#
.SYNOPSIS
Removes definition for the Content-Security-Policy and X-XSS-Protection headers.

.DESCRIPTION
Removes definition for the Content-Security-Policy and X-XSS-Protection headers.

.EXAMPLE
Remove-PodeSecurityContentSecurityPolicy
#>
function Remove-PodeSecurityContentSecurityPolicy {
    [CmdletBinding()]
    param()

    Remove-PodeSecurityHeader -Name 'Content-Security-Policy'
    Remove-PodeSecurityHeader -Name 'X-XSS-Protection'
}

<#
.SYNOPSIS
Set the value to use for the Permissions-Policy header.

.DESCRIPTION
Set the value to use for the Permissions-Policy header.

.PARAMETER Accelerometer
The values to use for the Accelerometer portion of the header.

.PARAMETER AmbientLightSensor
The values to use for the AmbientLightSensor portion of the header.

.PARAMETER Autoplay
The values to use for the Autoplay portion of the header.

.PARAMETER Battery
The values to use for the Battery portion of the header.

.PARAMETER Camera
The values to use for the Camera portion of the header.

.PARAMETER DisplayCapture
The values to use for the DisplayCapture portion of the header.

.PARAMETER DocumentDomain
The values to use for the DocumentDomain portion of the header.

.PARAMETER EncryptedMedia
The values to use for the EncryptedMedia portion of the header.

.PARAMETER Fullscreen
The values to use for the Fullscreen portion of the header.

.PARAMETER Gamepad
The values to use for the Gamepad portion of the header.

.PARAMETER Geolocation
The values to use for the Geolocation portion of the header.

.PARAMETER Gyroscope
The values to use for the Gyroscope portion of the header.

.PARAMETER InterestCohort
The values to use for the InterestCohort portal of the header.

.PARAMETER LayoutAnimations
The values to use for the LayoutAnimations portion of the header.

.PARAMETER LegacyImageFormats
The values to use for the LegacyImageFormats portion of the header.

.PARAMETER Magnetometer
The values to use for the Magnetometer portion of the header.

.PARAMETER Microphone
The values to use for the Microphone portion of the header.

.PARAMETER Midi
The values to use for the Midi portion of the header.

.PARAMETER OversizedImages
The values to use for the OversizedImages portion of the header.

.PARAMETER Payment
The values to use for the Payment portion of the header.

.PARAMETER PictureInPicture
The values to use for the PictureInPicture portion of the header.

.PARAMETER PublicKeyCredentials
The values to use for the PublicKeyCredentials portion of the header.

.PARAMETER Speakers
The values to use for the Speakers portion of the header.

.PARAMETER SyncXhr
The values to use for the SyncXhr portion of the header.

.PARAMETER UnoptimisedImages
The values to use for the UnoptimisedImages portion of the header.

.PARAMETER UnsizedMedia
The values to use for the UnsizedMedia portion of the header.

.PARAMETER Usb
The values to use for the Usb portion of the header.

.PARAMETER ScreenWakeLake
The values to use for the ScreenWakeLake portion of the header.

.PARAMETER WebShare
The values to use for the WebShare portion of the header.

.PARAMETER XrSpatialTracking
The values to use for the XrSpatialTracking portion of the header.

#>
function Set-PodeSecurityPermissionsPolicy {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSPossibleIncorrectComparisonWithNull', '')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]
        $Accelerometer,

        [Parameter()]
        [string[]]
        $AmbientLightSensor,

        [Parameter()]
        [string[]]
        $Autoplay,

        [Parameter()]
        [string[]]
        $Battery,

        [Parameter()]
        [string[]]
        $Camera,

        [Parameter()]
        [string[]]
        $DisplayCapture,

        [Parameter()]
        [string[]]
        $DocumentDomain,

        [Parameter()]
        [string[]]
        $EncryptedMedia,

        [Parameter()]
        [string[]]
        $Fullscreen,

        [Parameter()]
        [string[]]
        $Gamepad,

        [Parameter()]
        [string[]]
        $Geolocation,

        [Parameter()]
        [string[]]
        $Gyroscope,

        [Parameter()]
        [string[]]
        $InterestCohort,

        [Parameter()]
        [string[]]
        $LayoutAnimations,

        [Parameter()]
        [string[]]
        $LegacyImageFormats,

        [Parameter()]
        [string[]]
        $Magnetometer,

        [Parameter()]
        [string[]]
        $Microphone,

        [Parameter()]
        [string[]]
        $Midi,

        [Parameter()]
        [string[]]
        $OversizedImages,

        [Parameter()]
        [string[]]
        $Payment,

        [Parameter()]
        [string[]]
        $PictureInPicture,

        [Parameter()]
        [string[]]
        $PublicKeyCredentials,

        [Parameter()]
        [string[]]
        $Speakers,

        [Parameter()]
        [string[]]
        $SyncXhr,

        [Parameter()]
        [string[]]
        $UnoptimisedImages,

        [Parameter()]
        [string[]]
        $UnsizedMedia,

        [Parameter()]
        [string[]]
        $Usb,

        [Parameter()]
        [string[]]
        $ScreenWakeLake,

        [Parameter()]
        [string[]]
        $WebShare,

        [Parameter()]
        [string[]]
        $XrSpatialTracking
    )

    Set-PodeSecurityPermissionsPolicyInternal -Params $PSBoundParameters
}

<#
.SYNOPSIS
Adds additional values to already defined values for the Permissions-Policy header.

.DESCRIPTION
Adds additional values to already defined values for the Permissions-Policy header, instead of overriding them.

.PARAMETER Accelerometer
The values to add for the Accelerometer portion of the header.

.PARAMETER AmbientLightSensor
The values to add for the AmbientLightSensor portion of the header.

.PARAMETER Autoplay
The values to add for the Autoplay portion of the header.

.PARAMETER Battery
The values to add for the Battery portion of the header.

.PARAMETER Camera
The values to add for the Camera portion of the header.

.PARAMETER DisplayCapture
The values to add for the DisplayCapture portion of the header.

.PARAMETER DocumentDomain
The values to add for the DocumentDomain portion of the header.

.PARAMETER EncryptedMedia
The values to add for the EncryptedMedia portion of the header.

.PARAMETER Fullscreen
The values to add for the Fullscreen portion of the header.

.PARAMETER Gamepad
The values to add for the Gamepad portion of the header.

.PARAMETER Geolocation
The values to add for the Geolocation portion of the header.

.PARAMETER Gyroscope
The values to add for the Gyroscope portion of the header.

.PARAMETER InterestCohort
The values to use for the InterestCohort portal of the header.

.PARAMETER LayoutAnimations
The values to add for the LayoutAnimations portion of the header.

.PARAMETER LegacyImageFormats
The values to add for the LegacyImageFormats portion of the header.

.PARAMETER Magnetometer
The values to add for the Magnetometer portion of the header.

.PARAMETER Microphone
The values to add for the Microphone portion of the header.

.PARAMETER Midi
The values to add for the Midi portion of the header.

.PARAMETER OversizedImages
The values to add for the OversizedImages portion of the header.

.PARAMETER Payment
The values to add for the Payment portion of the header.

.PARAMETER PictureInPicture
The values to add for the PictureInPicture portion of the header.

.PARAMETER PublicKeyCredentials
The values to add for the PublicKeyCredentials portion of the header.

.PARAMETER Speakers
The values to add for the Speakers portion of the header.

.PARAMETER SyncXhr
The values to add for the SyncXhr portion of the header.

.PARAMETER UnoptimisedImages
The values to add for the UnoptimisedImages portion of the header.

.PARAMETER UnsizedMedia
The values to add for the UnsizedMedia portion of the header.

.PARAMETER Usb
The values to add for the Usb portion of the header.

.PARAMETER ScreenWakeLake
The values to add for the ScreenWakeLake portion of the header.

.PARAMETER WebShare
The values to add for the WebShare portion of the header.

.PARAMETER XrSpatialTracking
The values to add for the XrSpatialTracking portion of the header.

.EXAMPLE
Add-PodeSecurityPermissionsPolicy -AmbientLightSensor 'none'
#>
function Add-PodeSecurityPermissionsPolicy {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]
        $Accelerometer,

        [Parameter()]
        [string[]]
        $AmbientLightSensor,

        [Parameter()]
        [string[]]
        $Autoplay,

        [Parameter()]
        [string[]]
        $Battery,

        [Parameter()]
        [string[]]
        $Camera,

        [Parameter()]
        [string[]]
        $DisplayCapture,

        [Parameter()]
        [string[]]
        $DocumentDomain,

        [Parameter()]
        [string[]]
        $EncryptedMedia,

        [Parameter()]
        [string[]]
        $Fullscreen,

        [Parameter()]
        [string[]]
        $Gamepad,

        [Parameter()]
        [string[]]
        $Geolocation,

        [Parameter()]
        [string[]]
        $Gyroscope,

        [Parameter()]
        [string[]]
        $InterestCohort,

        [Parameter()]
        [string[]]
        $LayoutAnimations,

        [Parameter()]
        [string[]]
        $LegacyImageFormats,

        [Parameter()]
        [string[]]
        $Magnetometer,

        [Parameter()]
        [string[]]
        $Microphone,

        [Parameter()]
        [string[]]
        $Midi,

        [Parameter()]
        [string[]]
        $OversizedImages,

        [Parameter()]
        [string[]]
        $Payment,

        [Parameter()]
        [string[]]
        $PictureInPicture,

        [Parameter()]
        [string[]]
        $PublicKeyCredentials,

        [Parameter()]
        [string[]]
        $Speakers,

        [Parameter()]
        [string[]]
        $SyncXhr,

        [Parameter()]
        [string[]]
        $UnoptimisedImages,

        [Parameter()]
        [string[]]
        $UnsizedMedia,

        [Parameter()]
        [string[]]
        $Usb,

        [Parameter()]
        [string[]]
        $ScreenWakeLake,

        [Parameter()]
        [string[]]
        $WebShare,

        [Parameter()]
        [string[]]
        $XrSpatialTracking
    )

    Set-PodeSecurityPermissionsPolicyInternal -Params $PSBoundParameters -Append
}

<#
.SYNOPSIS
Removes definition for the Permissions-Policy header.

.DESCRIPTION
Removes definitions for the Permissions-Policy header.

.EXAMPLE
Remove-PodeSecurityPermissionsPolicy
#>
function Remove-PodeSecurityPermissionsPolicy {
    [CmdletBinding()]
    param()

    Remove-PodeSecurityHeader -Name 'Permissions-Policy'
}

<#
.SYNOPSIS
Set a value for the Referrer-Policy header.

.DESCRIPTION
Set a value for the Referrer-Policy header.

.PARAMETER Type
The Type to use.

.EXAMPLE
Set-PodeSecurityReferrerPolicy -Type No-Referrer
#>
function Set-PodeSecurityReferrerPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('No-Referrer', 'No-Referrer-When-Downgrade', 'Same-Origin', 'Origin', 'Strict-Origin',
            'Origin-When-Cross-Origin', 'Strict-Origin-When-Cross-Origin', 'Unsafe-Url')]
        [string]
        $Type
    )

    Add-PodeSecurityHeader -Name 'Referrer-Policy' -Value $Type.ToLowerInvariant()
}

<#
.SYNOPSIS
Removes definition for the Referrer-Policy header.

.DESCRIPTION
Removes definitions for the Referrer-Policy header.

.EXAMPLE
Remove-PodeSecurityReferrerPolicy
#>
function Remove-PodeSecurityReferrerPolicy {
    [CmdletBinding()]
    param()

    Remove-PodeSecurityHeader -Name 'Referrer-Policy'
}

<#
.SYNOPSIS
Set a value for the X-Content-Type-Options header.

.DESCRIPTION
Set a value for the X-Content-Type-Options header to "nosniff".

.EXAMPLE
Set-PodeSecurityContentTypeOptions
#>
function Set-PodeSecurityContentTypeOptions {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    param()

    Add-PodeSecurityHeader -Name 'X-Content-Type-Options' -Value 'nosniff'
}

<#
.SYNOPSIS
Removes definition for the X-Content-Type-Options header.

.DESCRIPTION
Removes definitions for the X-Content-Type-Options header.

.EXAMPLE
Remove-PodeSecurityContentTypeOptions
#>
function Remove-PodeSecurityContentTypeOptions {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    param()

    Remove-PodeSecurityHeader -Name 'X-Content-Type-Options'
}

<#
.SYNOPSIS
Set a value for the Strict-Transport-Security header.

.DESCRIPTION
Set a value for the Strict-Transport-Security header.

.PARAMETER Duration
The Duration the browser to respect the header in seconds. (Default: 1 year)

.PARAMETER IncludeSubDomains
If supplied, the header will have includeSubDomains.

.EXAMPLE
Set-PodeSecurityStrictTransportSecurity -Duration 86400 -IncludeSubDomains
#>
function Set-PodeSecurityStrictTransportSecurity {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]
        $Duration = 31536000,

        [switch]
        $IncludeSubDomains
    )

    if ($Duration -le 0) {
        # Invalid Strict-Transport-Security duration supplied
        throw ($PodeLocale.invalidStrictTransportSecurityDurationExceptionMessage -f $Duration)
    }

    $value = "max-age=$($Duration)"

    if ($IncludeSubDomains) {
        $value += '; includeSubDomains'
    }

    Add-PodeSecurityHeader -Name 'Strict-Transport-Security' -Value $value
}

<#
.SYNOPSIS
Removes definition for the Strict-Transport-Security header.

.DESCRIPTION
Removes definitions for the Strict-Transport-Security header.

.EXAMPLE
Remove-PodeSecurityStrictTransportSecurity
#>
function Remove-PodeSecurityStrictTransportSecurity {
    [CmdletBinding()]
    param()

    Remove-PodeSecurityHeader -Name 'Strict-Transport-Security'
}

<#
.SYNOPSIS
Removes definitions for the Cross-Origin headers.

.DESCRIPTION
Removes definitions for the Cross-Origin headers: Cross-Origin-Embedder-Policy, Cross-Origin-Opener-Policy, Cross-Origin-Resource-Policy

.PARAMETER Embed
Specifies a value for Cross-Origin-Embedder-Policy.

.PARAMETER Open
Specifies a value for Cross-Origin-Opener-Policy.

.PARAMETER Resource
Specifies a value for Cross-Origin-Resource-Policy.

.EXAMPLE
Set-PodeSecurityCrossOrigin -Embed Require-Corp -Open Same-Origin -Resource Same-Origin
#>
function Set-PodeSecurityCrossOrigin {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('', 'Unsafe-None', 'Require-Corp')]
        [string]
        $Embed = '',

        [Parameter()]
        [ValidateSet('', 'Unsafe-None', 'Same-Origin-Allow-Popups', 'Same-Origin')]
        [string]
        $Open = '',

        [Parameter()]
        [ValidateSet('', 'Same-Site', 'Same-Origin', 'Cross-Origin')]
        [string]
        $Resource = ''
    )

    Add-PodeSecurityHeader -Name 'Cross-Origin-Embedder-Policy' -Value $Embed.ToLowerInvariant()
    Add-PodeSecurityHeader -Name 'Cross-Origin-Opener-Policy' -Value $Open.ToLowerInvariant()
    Add-PodeSecurityHeader -Name 'Cross-Origin-Resource-Policy' -Value $Resource.ToLowerInvariant()
}

<#
.SYNOPSIS
Removes definitions for the Cross-Origin headers.

.DESCRIPTION
Removes definitions for the Cross-Origin headers: Cross-Origin-Embedder-Policy, Cross-Origin-Opener-Policy, Cross-Origin-Resource-Policy

.EXAMPLE
Remove-PodeSecurityCrossOrigin
#>
function Remove-PodeSecurityCrossOrigin {
    [CmdletBinding()]
    param()

    Remove-PodeSecurityHeader -Name 'Cross-Origin-Embedder-Policy'
    Remove-PodeSecurityHeader -Name 'Cross-Origin-Opener-Policy'
    Remove-PodeSecurityHeader -Name 'Cross-Origin-Resource-Policy'
}

<#
.SYNOPSIS
Set definitions for Access-Control headers.

.DESCRIPTION
Removes definitions for the Access-Control headers: Access-Control-Allow-Origin, Access-Control-Allow-Methods, Access-Control-Allow-Headers, Access-Control-Max-Age, Access-Control-Allow-Credentials

.PARAMETER Origin
Specifies a value for Access-Control-Allow-Origin.

.PARAMETER Methods
Specifies a value for Access-Control-Allow-Methods.

.PARAMETER Headers
Specifies a value for Access-Control-Allow-Headers.

.PARAMETER Duration
Specifies a value for Access-Control-Max-Age in seconds. (Default: 7200)
Use a value of one for debugging any CORS related issues

.PARAMETER Credentials
Specifies a value for Access-Control-Allow-Credentials

.PARAMETER WithOptions
If supplied, a global Options Route will be created.

.PARAMETER AuthorizationHeader
Add 'Authorization' to the headers list

.PARAMETER AutoHeaders
Automatically populate the list of allowed Headers based on the OpenApi definition.
This parameter can works in conjuntion with CrossDomainXhrRequests,AuthorizationHeader and Headers (Headers cannot be '*').
By default add  'content-type' to the headers

.PARAMETER AutoMethods
Automatically populate the list of allowed Methods based on the defined Routes.
This parameter can works in conjuntion with the parameter Methods, if Methods is not including '*'

.PARAMETER CrossDomainXhrRequests
Add 'x-requested-with' to the list of allowed headers
More info available here:
https://fetch.spec.whatwg.org/
https://learn.microsoft.com/en-us/aspnet/core/security/cors?view=aspnetcore-7.0#credentials-in-cross-origin-requests
https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS

.EXAMPLE
Set-PodeSecurityAccessControl -Origin '*' -Methods '*' -Headers '*' -Duration 7200
#>
function Set-PodeSecurityAccessControl {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Origin,

        [Parameter()]
        [ValidateSet('', 'Connect', 'Delete', 'Get', 'Head', 'Merge', 'Options', 'Patch', 'Post', 'Put', 'Trace', '*')]
        [string[]]
        $Methods = '',

        [Parameter()]
        [string[]]
        $Headers,

        [Parameter()]
        [int]
        $Duration = 7200,

        [switch]
        $Credentials,

        [switch]
        $WithOptions,

        [switch]
        $AuthorizationHeader,

        [switch]
        $AutoHeaders,

        [switch]
        $AutoMethods,

        [switch]
        $CrossDomainXhrRequests
    )

    # origin
    Add-PodeSecurityHeader -Name 'Access-Control-Allow-Origin' -Value $Origin

    # methods
    if (![string]::IsNullOrWhiteSpace($Methods)) {
        if ($Methods -icontains '*') {
            Add-PodeSecurityHeader -Name 'Access-Control-Allow-Methods' -Value '*'
        }
        else {
            Add-PodeSecurityHeader -Name 'Access-Control-Allow-Methods' -Value ($Methods -join ', ')
        }
    }

    # headers
    if (![string]::IsNullOrWhiteSpace($Headers) -or $AuthorizationHeader -or $CrossDomainXhrRequests) {
        if ($Headers -icontains '*') {
            if ($Credentials) {
                # When Credentials is passed, The * wildcard for Headers will be taken as a literal string and not a wildcard
                throw ($PodeLocale.credentialsPassedWildcardForHeadersLiteralExceptionMessage)
            }

            $Headers = @('*')
        }

        if ($AuthorizationHeader) {
            if ([string]::IsNullOrWhiteSpace($Headers)) {
                $Headers = @()
            }

            $Headers += 'Authorization'
        }

        if ($CrossDomainXhrRequests) {
            if ([string]::IsNullOrWhiteSpace($Headers)) {
                $Headers = @()
            }
            $Headers += 'x-requested-with'
        }
        Add-PodeSecurityHeader -Name 'Access-Control-Allow-Headers' -Value (($Headers | Select-Object -Unique) -join ', ')
    }

    if ($AutoHeaders) {
        if ($Headers -icontains '*') {
            # The * wildcard for Headers is incompatible with the AutoHeaders switch
            throw ($PodeLocale.wildcardHeadersIncompatibleWithAutoHeadersExceptionMessage)
        }

        Add-PodeSecurityHeader -Name 'Access-Control-Allow-Headers' -Value 'content-type' -Append
        $PodeContext.Server.Security.autoHeaders = $true
    }

    if ($AutoMethods) {
        if ($Methods -icontains '*') {
            # The * wildcard for Methods is incompatible with the AutoMethods switch
            throw ($PodeLocale.wildcardMethodsIncompatibleWithAutoMethodsExceptionMessage)
        }
        if ($WithOptions) {
            Add-PodeSecurityHeader -Name 'Access-Control-Allow-Methods' -Value 'Options' -Append
        }
        $PodeContext.Server.Security.autoMethods = $true
    }

    # duration
    if ($Duration -le 0) {
        # Invalid Access-Control-Max-Age duration supplied
        throw ($PodeLocale.invalidAccessControlMaxAgeDurationExceptionMessage -f $Duration)
    }

    Add-PodeSecurityHeader -Name 'Access-Control-Max-Age' -Value $Duration

    # creds
    if ($Credentials) {
        Add-PodeSecurityHeader -Name 'Access-Control-Allow-Credentials' -Value 'true'
    }

    # opts route
    if ($WithOptions) {
        Add-PodeRoute -Method Options -Path * -ScriptBlock {
            Set-PodeResponseStatus -Code 200
        }
    }
}

<#
.SYNOPSIS
Removes definitions for the Access-Control headers.

.DESCRIPTION
Removes definitions for the Access-Control headers: Access-Control-Allow-Origin, Access-Control-Allow-Methods, Access-Control-Allow-Headers, Access-Control-Max-Age, Access-Control-Allow-Credentials

.EXAMPLE
Remove-PodeSecurityAccessControl
#>
function Remove-PodeSecurityAccessControl {
    [CmdletBinding()]
    param()

    Remove-PodeSecurityHeader -Name 'Access-Control-Allow-Origin'
    Remove-PodeSecurityHeader -Name 'Access-Control-Allow-Methods'
    Remove-PodeSecurityHeader -Name 'Access-Control-Allow-Headers'
    Remove-PodeSecurityHeader -Name 'Access-Control-Max-Age'
    Remove-PodeSecurityHeader -Name 'Access-Control-Allow-Credentials'
}