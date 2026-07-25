param(
    [string]$BaseUrl = "http://127.0.0.1:5055",
    [string]$SqlServer = ".",
    [string]$Database = "RasAlSouqDb"
)

$ErrorActionPreference = "Stop"

$suffix = (Get-Date).ToString("yyyyMMddHHmmss")
$personEmail = "person$suffix@test.com"
$companyEmail = "company$suffix@test.com"
$password = "P@ssw0rd123!"
$newPassword = "N3wP@ssw0rd123!"
$results = @()

function Add-Result($name, $ok, $details) {
    $script:results += [pscustomobject]@{
        Endpoint = $name
        Status = if ($ok) { "PASS" } else { "FAIL" }
        Details = $details
    }
}

function Invoke-Api {
    param(
        [string]$Method,
        [string]$Url,
        [string]$Body = "",
        [hashtable]$Headers = @{},
        [string]$ContentType = "application/json"
    )
    if ([string]::IsNullOrWhiteSpace($Body)) {
        return Invoke-RestMethod -Method $Method -Uri $Url -Headers $Headers
    }
    return Invoke-RestMethod -Method $Method -Uri $Url -Headers $Headers -ContentType $ContentType -Body $Body
}

function Sql-Scalar([string]$query) {
    return (sqlcmd -S $SqlServer -d $Database -E -C -h -1 -W -Q "SET NOCOUNT ON;$query" | Select-Object -First 1).Trim()
}

function Sql-NonQuery([string]$query) {
    sqlcmd -S $SqlServer -d $Database -E -C -Q $query | Out-Null
}

$personLogin = $null
$companyLogin = $null
$adminToken = ""
$adminUserId = ""
$companyToken = ""
$productId = ""
$cityId = ""
$categoryId = ""
$originCountry = ""
$destinationCountry = ""
$loadingPort = ""
$arrivalPort = ""
$unit = ""
$sampleImage = "C:\Users\rana\.cursor\projects\d-Apps-Ras-Al-souq-RasAlSouqPresentaionLayer\assets\c__Users_rana_AppData_Roaming_Cursor_User_workspaceStorage_395ad3411b01d08ae29880a402847480_images_koko-14d4bcfd-9d0b-4a86-b5b8-3447f3a2a5be.png"

try {
    $body = @{
        fullName = "Test Person"
        email = $personEmail
        password = $password
        phoneNumber = "0500000001"
        fcmToken = "fcm-person-token"
    } | ConvertTo-Json
    $personReg = Invoke-Api -Method Post -Url "$BaseUrl/api/Auth/register-person" -Body $body
    Add-Result "POST /api/Auth/register-person" $true "userId=$($personReg.userId)"
} catch { Add-Result "POST /api/Auth/register-person" $false $_.Exception.Message }

try {
    $body = @{ email = $personEmail } | ConvertTo-Json
    Invoke-Api -Method Post -Url "$BaseUrl/api/Auth/send-email-otp" -Body $body | Out-Null
    Add-Result "POST /api/Auth/send-email-otp" $true "OTP send requested"
} catch { Add-Result "POST /api/Auth/send-email-otp" $false $_.Exception.Message }

try {
    $otp = Sql-Scalar "SELECT TOP 1 Code FROM EmailOtps WHERE Email='$personEmail' ORDER BY Id DESC"
    if ([string]::IsNullOrWhiteSpace($otp)) { throw "OTP not found in DB" }
    $body = @{ email = $personEmail; otp = $otp } | ConvertTo-Json
    Invoke-Api -Method Post -Url "$BaseUrl/api/Auth/verify-email-otp" -Body $body | Out-Null
    Add-Result "POST /api/Auth/verify-email-otp" $true "OTP verified"
} catch { Add-Result "POST /api/Auth/verify-email-otp" $false $_.Exception.Message }

try {
    $body = @{
        loginProviderName = "Local"
        email = $personEmail
        password = $password
        fcmToken = "fcm-person-token"
    } | ConvertTo-Json
    $personLogin = Invoke-Api -Method Post -Url "$BaseUrl/api/Auth/login" -Body $body
    Add-Result "POST /api/Auth/login (person)" $true "Token returned"
} catch { Add-Result "POST /api/Auth/login (person)" $false $_.Exception.Message }

if ($personLogin) {
    try {
        $body = @{ currentPassword = $password; newPassword = $newPassword } | ConvertTo-Json
        Invoke-Api -Method Post -Url "$BaseUrl/api/Auth/change-password" -Body $body -Headers @{ Authorization = "Bearer $($personLogin.Token)" } | Out-Null
        Add-Result "POST /api/Auth/change-password" $true "Password changed"
    } catch { Add-Result "POST /api/Auth/change-password" $false $_.Exception.Message }
}

try {
    $body = @{
        providerName = "Email"
        destination = $personEmail
    } | ConvertTo-Json
    Invoke-Api -Method Post -Url "$BaseUrl/api/Auth/forgot-password/request" -Body $body | Out-Null
    $resetCode = Sql-Scalar "SELECT TOP 1 Code FROM PasswordResetCodes WHERE ProviderName='Email' AND Destination='$personEmail' ORDER BY Id DESC"
    if ([string]::IsNullOrWhiteSpace($resetCode)) { throw "Reset code not found in DB" }
    $body2 = @{
        providerName = "Email"
        destination = $personEmail
        code = $resetCode
        newPassword = $password
    } | ConvertTo-Json
    Invoke-Api -Method Post -Url "$BaseUrl/api/Auth/forgot-password/reset" -Body $body2 | Out-Null
    Add-Result "POST /api/Auth/forgot-password/request + reset" $true "Email reset flow succeeded"
} catch { Add-Result "POST /api/Auth/forgot-password/request + reset" $false $_.Exception.Message }

try {
    Sql-NonQuery "UPDATE Users SET RoleId=1, IsVerified=1, IsActive=1 WHERE Email='$personEmail';"
    $body = @{
        loginProviderName = "Local"
        email = $personEmail
        password = $password
        fcmToken = "fcm-person-token"
    } | ConvertTo-Json
    $adminLogin = Invoke-Api -Method Post -Url "$BaseUrl/api/Auth/login" -Body $body
    $adminToken = $adminLogin.Token
    $adminUserId = $adminLogin.Id
    Add-Result "Admin promotion + login" $true "Admin token acquired"
} catch { Add-Result "Admin promotion + login" $false $_.Exception.Message }

try {
    $body = @{
        fullName = "Test Company"
        companyName = "Ras Test Co"
        email = $companyEmail
        password = $password
        phoneNumber = "0500000002"
        landNumber = "026666666"
        licenseNumber = "LIC-$suffix"
        fcmToken = "fcm-company-token"
        licencePath = "/licenses/lic1.jpg"
        companyImagePaths = @("/company/seed1.jpg")
        birthDate = "1990-01-01"
        commercialRegister = "CR-$suffix"
        taxNumber = "TX-$suffix"
    } | ConvertTo-Json
    $companyReg = Invoke-Api -Method Post -Url "$BaseUrl/api/Auth/register-company" -Body $body
    Add-Result "POST /api/Auth/register-company" $true "userId=$($companyReg.userId)"
} catch { Add-Result "POST /api/Auth/register-company" $false $_.Exception.Message }

if (-not [string]::IsNullOrWhiteSpace($adminToken)) {
    try {
        $categoryBody = @{
            nameEn = "Test Category $suffix"
            imgPath = "/images/categories/test-$suffix.jpg"
        } | ConvertTo-Json
        $categoryRes = Invoke-Api -Method Post -Url "$BaseUrl/api/Categories" -Body $categoryBody -Headers @{ Authorization = "Bearer $adminToken" }
        $categoryId = $categoryRes.categoryId
        Add-Result "POST /api/Categories" $true "categoryId=$categoryId"
    } catch { Add-Result "POST /api/Categories" $false $_.Exception.Message }

    if (-not [string]::IsNullOrWhiteSpace($categoryId)) {
        try {
            $categoryUpdateBody = @{
                nameEn = "Updated Category $suffix"
                imgPath = "/images/categories/updated-$suffix.jpg"
            } | ConvertTo-Json
            Invoke-Api -Method Put -Url "$BaseUrl/api/Categories/$categoryId" -Body $categoryUpdateBody -Headers @{ Authorization = "Bearer $adminToken" } | Out-Null
            Add-Result "PUT /api/Categories/{categoryId}" $true "Category updated"
        } catch { Add-Result "PUT /api/Categories/{categoryId}" $false $_.Exception.Message }

        try {
            $uploadRaw = curl.exe -s -X POST "$BaseUrl/api/Categories/$categoryId/image/upload" -H "Authorization: Bearer $adminToken" -F "file=@$sampleImage"
            $uploadObj = $uploadRaw | ConvertFrom-Json
            if (-not $uploadObj.imgPath) { throw "imgPath missing in response" }
            Add-Result "POST /api/Categories/{categoryId}/image/upload" $true "Image uploaded"
        } catch { Add-Result "POST /api/Categories/{categoryId}/image/upload" $false $_.Exception.Message }
    }

    $bannerId = ""
    try {
        $bannerRaw = curl.exe -s -X POST "$BaseUrl/api/HomeBanners" -H "Authorization: Bearer $adminToken" -F "file=@$sampleImage" -F "linkUrl=https://example.com/banner-$suffix" -F "displayOrder=1"
        $bannerObj = $bannerRaw | ConvertFrom-Json
        if (-not $bannerObj.id) { throw "Banner id missing in response" }
        $bannerId = "$($bannerObj.id)"
        Add-Result "POST /api/HomeBanners" $true "bannerId=$bannerId"
    } catch { Add-Result "POST /api/HomeBanners" $false $_.Exception.Message }

    try {
        $banners = Invoke-Api -Method Get -Url "$BaseUrl/api/HomeBanners"
        $bannerCount = @($banners.items).Count
        Add-Result "GET /api/HomeBanners" $true "items=$bannerCount"
    } catch { Add-Result "GET /api/HomeBanners" $false $_.Exception.Message }

    try {
        $bannersCached = Invoke-Api -Method Get -Url "$BaseUrl/api/HomeBanners"
        $bannerCountCached = @($bannersCached.items).Count
        Add-Result "GET /api/HomeBanners (cache recheck)" $true "items=$bannerCountCached"
    } catch { Add-Result "GET /api/HomeBanners (cache recheck)" $false $_.Exception.Message }

    if (-not [string]::IsNullOrWhiteSpace($bannerId)) {
        try {
            Invoke-Api -Method Delete -Url "$BaseUrl/api/HomeBanners/$bannerId" -Headers @{ Authorization = "Bearer $adminToken" } | Out-Null
            Add-Result "DELETE /api/HomeBanners/{bannerId}" $true "Banner deleted"
        } catch { Add-Result "DELETE /api/HomeBanners/{bannerId}" $false $_.Exception.Message }
    }

    try {
        $pending = Invoke-Api -Method Get -Url "$BaseUrl/api/admin/companies/pending" -Headers @{ Authorization = "Bearer $adminToken" }
        $target = $pending | Where-Object { $_.email -eq $companyEmail } | Select-Object -First 1
        if (-not $target) { throw "Pending company not found." }
        Invoke-Api -Method Post -Url "$BaseUrl/api/admin/companies/$($target.id)/approve" -Headers @{ Authorization = "Bearer $adminToken" } | Out-Null
        Add-Result "GET/POST /api/admin/companies" $true "Company approved"
    } catch { Add-Result "GET/POST /api/admin/companies" $false $_.Exception.Message }
}

try {
    $body = @{
        loginProviderName = "Local"
        email = $companyEmail
        password = $password
        fcmToken = "fcm-company-token"
    } | ConvertTo-Json
    $companyLogin = Invoke-Api -Method Post -Url "$BaseUrl/api/Auth/login" -Body $body
    $companyToken = $companyLogin.Token
    if ([string]::IsNullOrWhiteSpace($companyLogin.companyName)) { throw "companyName missing in login response" }
    Add-Result "POST /api/Auth/login (company)" $true "Company login + companyName in response"
} catch { Add-Result "POST /api/Auth/login (company)" $false $_.Exception.Message }

if (-not [string]::IsNullOrWhiteSpace($companyToken)) {
    try {
        $uploadRaw = curl.exe -s -X POST "$BaseUrl/api/CompanyLicence/upload" -H "Authorization: Bearer $companyToken" -F "file=@$sampleImage"
        $uploadObj = $uploadRaw | ConvertFrom-Json
        if (-not $uploadObj.licencePath) { throw "licencePath missing" }
        Add-Result "POST /api/CompanyLicence/upload" $true "Licence uploaded"
    } catch { Add-Result "POST /api/CompanyLicence/upload" $false $_.Exception.Message }

    try {
        $originCountry = Sql-Scalar "SELECT TOP 1 CountryNameEn FROM Countries ORDER BY Id"
        $destinationCountry = Sql-Scalar "SELECT TOP 1 CountryNameEn FROM Countries ORDER BY Id DESC"
        $originCountryId = Sql-Scalar "SELECT TOP 1 Id FROM Countries WHERE CountryNameEn=N'$originCountry'"
        $destinationCountryId = Sql-Scalar "SELECT TOP 1 Id FROM Countries WHERE CountryNameEn=N'$destinationCountry'"
        $loadingPort = Sql-Scalar "SELECT TOP 1 PortNameEn FROM Ports WHERE CountryId=$originCountryId ORDER BY Id"
        $arrivalPort = Sql-Scalar "SELECT TOP 1 PortNameEn FROM Ports WHERE CountryId=$destinationCountryId ORDER BY Id"
        $unit = Sql-Scalar "SELECT TOP 1 UnitNameEn FROM Units ORDER BY Id"

        $productTypesRaw = sqlcmd -S $SqlServer -d $Database -E -C -h -1 -W -Q "SET NOCOUNT ON;SELECT TypeNameEn FROM ProductTypes ORDER BY Id"
        $productTypes = @($productTypesRaw | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() })
        if (@($productTypes).Count -eq 0) { throw "No product types found." }

        $createdProductIds = @()
        $createdCount = 0
        foreach ($typeName in $productTypes) {
            $productRaw = curl.exe -s -X POST "$BaseUrl/api/Products" `
                -H "Authorization: Bearer $companyToken" `
                -F "nameEn=Integration Product $typeName $suffix" `
                -F "usdPrice=99.5" `
                -F "quantity=200" `
                -F "descriptionEn=Integration test product $typeName" `
                -F "productTypeName=$typeName" `
                -F "unitName=$unit" `
                -F "originCountryName=$originCountry" `
                -F "destinationCountryName=$destinationCountry" `
                -F "loadingPortName=$loadingPort" `
                -F "arrivalPortName=$arrivalPort"
            $product = $productRaw | ConvertFrom-Json
            if (-not $product.productId) { throw "Product creation failed for type '$typeName'" }
            $createdProductIds += "$($product.productId)"
            $createdCount++
        }

        $productId = $createdProductIds[0]
        $productType = $productTypes[0]
        Add-Result "POST /api/Products" $true "created=$createdCount firstProductId=$productId"
    } catch { Add-Result "POST /api/Products" $false $_.Exception.Message }

    try {
        $allProducts = Invoke-Api -Method Get -Url "$BaseUrl/api/Products"
        $allCount = @($allProducts.items).Count
        Add-Result "GET /api/Products" $true "items=$allCount"
    } catch { Add-Result "GET /api/Products" $false $_.Exception.Message }

    try {
        $allProductsCached = Invoke-Api -Method Get -Url "$BaseUrl/api/Products"
        $allCountCached = @($allProductsCached.items).Count
        Add-Result "GET /api/Products (cache recheck)" $true "items=$allCountCached"
    } catch { Add-Result "GET /api/Products (cache recheck)" $false $_.Exception.Message }

    if (-not [string]::IsNullOrWhiteSpace($productType)) {
        try {
            $byType = Invoke-Api -Method Get -Url "$BaseUrl/api/Products/by-type/$([uri]::EscapeDataString($productType))"
            $typeCount = @($byType.items).Count
            Add-Result "GET /api/Products/by-type/{productTypeName}" $true "items=$typeCount"
        } catch { Add-Result "GET /api/Products/by-type/{productTypeName}" $false $_.Exception.Message }

        try {
            $byTypeCached = Invoke-Api -Method Get -Url "$BaseUrl/api/Products/by-type/$([uri]::EscapeDataString($productType))"
            $typeCountCached = @($byTypeCached.items).Count
            Add-Result "GET /api/Products/by-type/{productTypeName} (cache recheck)" $true "items=$typeCountCached"
        } catch { Add-Result "GET /api/Products/by-type/{productTypeName} (cache recheck)" $false $_.Exception.Message }
    }

    try {
        $featured = Invoke-Api -Method Get -Url "$BaseUrl/api/Products/featured"
        $featuredCount = @($featured.items).Count
        Add-Result "GET /api/Products/featured" $true "items=$featuredCount"
    } catch { Add-Result "GET /api/Products/featured" $false $_.Exception.Message }

    try {
        $featuredCached = Invoke-Api -Method Get -Url "$BaseUrl/api/Products/featured"
        $featuredCountCached = @($featuredCached.items).Count
        Add-Result "GET /api/Products/featured (cache recheck)" $true "items=$featuredCountCached"
    } catch { Add-Result "GET /api/Products/featured (cache recheck)" $false $_.Exception.Message }

    if (-not [string]::IsNullOrWhiteSpace($productId)) {
        try {
            $viewsRes = Invoke-Api -Method Post -Url "$BaseUrl/api/Products/$productId/increase-view"
            Add-Result "POST /api/Products/{productId}/increase-view" $true "viewsCount=$($viewsRes.viewsCount)"
        } catch { Add-Result "POST /api/Products/{productId}/increase-view" $false $_.Exception.Message }
    }

    if (-not [string]::IsNullOrWhiteSpace($adminUserId)) {
        try {
            $offerBody = @{
                toUserId = $adminUserId
                countryName = $originCountry
                portName = $loadingPort
                deliveryWindow = "7 days"
                productId = $productId
                requestedQuantity = 100
                unitName = $unit
                unitPrice = 12.5
                totalPrice = 1100
            } | ConvertTo-Json
            $offerRes = Invoke-Api -Method Post -Url "$BaseUrl/api/Offers/OfferOnRequests" -Body $offerBody -Headers @{ Authorization = "Bearer $companyToken" }
            Add-Result "POST /api/Offers/OfferOnRequests" $true "offerId=$($offerRes.id)"
        } catch { Add-Result "POST /api/Offers/OfferOnRequests" $false $_.Exception.Message }

        try {
            $offerNegBody = @{
                toUserId = $adminUserId
                productId = $productId
                offeredPrice = 900
                unitName = $unit
                baseUnitPrice = 12.5
                requestedQuantity = 100
            } | ConvertTo-Json
            $offerNegRes = Invoke-Api -Method Post -Url "$BaseUrl/api/Offers/OfferOnNegotiable" -Body $offerNegBody -Headers @{ Authorization = "Bearer $companyToken" }
            Add-Result "POST /api/Offers/OfferOnNegotiable" $true "offerNegotiableId=$($offerNegRes.id)"
        } catch { Add-Result "POST /api/Offers/OfferOnNegotiable" $false $_.Exception.Message }

        try {
            $offerNegGet = Invoke-Api -Method Get -Url "$BaseUrl/api/Offers/OfferOnNegotiable?productId=$productId" -Headers @{ Authorization = "Bearer $companyToken" }
            $offerNegCount = @($offerNegGet).Count
            Add-Result "GET /api/Offers/OfferOnNegotiable" $true "results=$offerNegCount"
        } catch { Add-Result "GET /api/Offers/OfferOnNegotiable" $false $_.Exception.Message }
    }

    try {
        $cityId = Sql-Scalar "SELECT TOP 1 CAST(Id AS NVARCHAR(36)) FROM Cities ORDER BY CityName"
        $body = @{
            cityId = $cityId
            addressLine1 = "Street 1, Building A"
            addressLine2 = "Floor 2"
        } | ConvertTo-Json
        Invoke-Api -Method Post -Url "$BaseUrl/api/Addresses" -Body $body -Headers @{ Authorization = "Bearer $companyToken" } | Out-Null
        Add-Result "POST /api/Addresses" $true "Address created"
    } catch { Add-Result "POST /api/Addresses" $false $_.Exception.Message }

    if (-not [string]::IsNullOrWhiteSpace($productId)) {
        try {
            $uploadRaw = curl.exe -s -X POST "$BaseUrl/api/ProductAssets/$productId/images/upload" -H "Authorization: Bearer $companyToken" -F "file=@$sampleImage"
            $uploadObj = $uploadRaw | ConvertFrom-Json
            Add-Result "POST /api/ProductAssets/{productId}/images/upload" $true "imageId=$($uploadObj.id)"
        } catch { Add-Result "POST /api/ProductAssets/{productId}/images/upload" $false $_.Exception.Message }

        try {
            $doc = "D:\Apps\Ras Al souq\RasAlSouqPresentaionLayer\API_ENDPOINTS_RESPONSE_GUIDE.md"
            $uploadRaw = curl.exe -s -X POST "$BaseUrl/api/ProductAssets/$productId/documents/upload" -H "Authorization: Bearer $companyToken" -F "file=@$doc"
            $uploadObj = $uploadRaw | ConvertFrom-Json
            Add-Result "POST /api/ProductAssets/{productId}/documents/upload" $true "documentId=$($uploadObj.id)"
        } catch { Add-Result "POST /api/ProductAssets/{productId}/documents/upload" $false $_.Exception.Message }
    }

    if (($personLogin -ne $null) -and (-not [string]::IsNullOrWhiteSpace($productId))) {
        try {
            $cartBody = @{
                productId = $productId
                quantity = 2
                unitName = $unit
            } | ConvertTo-Json
            $cartAdd = Invoke-Api -Method Post -Url "$BaseUrl/api/Carts/items" -Body $cartBody -Headers @{ Authorization = "Bearer $($personLogin.Token)" }
            Add-Result "POST /api/Carts/items" $true "cartItemId=$($cartAdd.cartItemId)"
        } catch { Add-Result "POST /api/Carts/items" $false $_.Exception.Message }

        try {
            $myCart = Invoke-Api -Method Get -Url "$BaseUrl/api/Carts/me" -Headers @{ Authorization = "Bearer $($personLogin.Token)" }
            $itemsCount = @($myCart.items).Count
            Add-Result "GET /api/Carts/me" $true "items=$itemsCount"
        } catch { Add-Result "GET /api/Carts/me" $false $_.Exception.Message }

        try {
            $myCartCached = Invoke-Api -Method Get -Url "$BaseUrl/api/Carts/me" -Headers @{ Authorization = "Bearer $($personLogin.Token)" }
            $itemsCountCached = @($myCartCached.items).Count
            Add-Result "GET /api/Carts/me (cache recheck)" $true "items=$itemsCountCached"
        } catch { Add-Result "GET /api/Carts/me (cache recheck)" $false $_.Exception.Message }
    }

    try {
        $geo = Invoke-Api -Method Get -Url "$BaseUrl/api/Geo/countries/$originCountry/ports"
        $portsCount = @($geo.ports).Count
        Add-Result "GET /api/Geo/countries/{countryName}/ports" $true "ports=$portsCount"
    } catch { Add-Result "GET /api/Geo/countries/{countryName}/ports" $false $_.Exception.Message }

    try {
        $geoCached = Invoke-Api -Method Get -Url "$BaseUrl/api/Geo/countries/$originCountry/ports"
        $portsCountCached = @($geoCached.ports).Count
        Add-Result "GET /api/Geo/countries/{countryName}/ports (cache recheck)" $true "ports=$portsCountCached"
    } catch { Add-Result "GET /api/Geo/countries/{countryName}/ports (cache recheck)" $false $_.Exception.Message }

    try {
        $shippingBody = @{
            fromCountryName = $originCountry
            fromPortName = $loadingPort
            toCountryName = $destinationCountry
            toPortName = $arrivalPort
            priceUsd = 1000
            shippingCostUsd = 200
            phoneNumber = "0500000999"
            container20ftPriceUsd = 1500
            container40ftPriceUsd = 2500
        } | ConvertTo-Json
        $shippingCreate = Invoke-Api -Method Post -Url "$BaseUrl/api/InternationalShipping/posts" -Body $shippingBody -Headers @{ Authorization = "Bearer $companyToken" }
        Add-Result "POST /api/InternationalShipping/posts" $true "shippingPostId=$($shippingCreate.id)"
    } catch { Add-Result "POST /api/InternationalShipping/posts" $false $_.Exception.Message }

    try {
        $searchUrl = "$BaseUrl/api/InternationalShipping/search?fromCountryName=$([uri]::EscapeDataString($originCountry))&fromPortName=$([uri]::EscapeDataString($loadingPort))&toCountryName=$([uri]::EscapeDataString($destinationCountry))&toPortName=$([uri]::EscapeDataString($arrivalPort))"
        $shippingResults = Invoke-Api -Method Get -Url $searchUrl
        $count = @($shippingResults).Count
        Add-Result "GET /api/InternationalShipping/search" $true "results=$count"
    } catch { Add-Result "GET /api/InternationalShipping/search" $false $_.Exception.Message }

    try {
        $searchUrlCached = "$BaseUrl/api/InternationalShipping/search?fromCountryName=$([uri]::EscapeDataString($originCountry))&fromPortName=$([uri]::EscapeDataString($loadingPort))&toCountryName=$([uri]::EscapeDataString($destinationCountry))&toPortName=$([uri]::EscapeDataString($arrivalPort))"
        $shippingResultsCached = Invoke-Api -Method Get -Url $searchUrlCached
        $countCached = @($shippingResultsCached).Count
        Add-Result "GET /api/InternationalShipping/search (cache recheck)" $true "results=$countCached"
    } catch { Add-Result "GET /api/InternationalShipping/search (cache recheck)" $false $_.Exception.Message }
}

$results | Format-Table -AutoSize
