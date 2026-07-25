# RasAlSouq API - Endpoint Response Guide

This file describes what each endpoint returns (success and common error responses).

## Base Notes

- Auth header format for protected endpoints: `Authorization: Bearer <token>`
- Most error responses follow:
  - `{"message":"..."}`
- Swagger is available in development at `/swagger`.

---

## 1) Auth Endpoints
should return the Token and the important info
### `POST /api/Auth/register-person`
Creates a buyer account (unverified by default).
**Success (200)**
```json
{
  "message": "Person account created successfully.",
  "userId": "guid-string"
}
```

**Errors**
- `400` - missing/invalid input
- `409` - email already exists

---

### `POST /api/Auth/register-company`
Creates a seller/company account (pending admin approval).
**Success (200)**
```json
{
  "message": "Company account created and pending admin approval.",
  "userId": "guid-string"
}
```

**Request Body (important fields)**
```json
{
  "fullName": "Owner Name",
  "companyName": "Company Legal Name",
  "email": "company@email.com",
  "password": "P@ssw0rd",
  "phoneNumber": "optional",
  "landNumber": "optional",
  "licenseNumber": "optional",
  "licencePath": "/licenses/file.pdf",
  "birthDate": "optional (yyyy-MM-dd)",
  "commercialRegister": "optional",
  "taxNumber": "optional",
  "companyImagePaths": ["/company-images/a.jpg"]
}
```

**Errors**
- `400` - missing/invalid input (for example missing `LicencePath`)
- `409` - email already exists

---

### `POST /api/Auth/login`

Supports Local / Google / Apple / Facebook login.

**Success (200)**
```json
{
  "token": "jwt-token",
  "id": "user-id",
  "email": "user@email.com",
  "name": "User Name",
  "companyName": "optional-company-name",
  "roleName": "Admin|Seller|Buyer",
  "phone": "optional",
  "isCompanyAccount": true,
  "licenseNumber": "optional",
  "licencePath": "/licenses/lic.jpg",
  "companyImages": [
    {
      "id": 1,
      "imagePath": "/company-images/...jpg",
      "isPrimary": true
    }
  ]
}
```

**Errors**
- `400` - invalid request/provider/input
- `401` - unauthorized, including:
  - email not verified
  - company not approved
  - invalid credentials/token

---

### `POST /api/Auth/change-password` (Authorized)

Changes password using current password.

**Request Body**
```json
{
  "currentPassword": "old-password",
  "newPassword": "new-password"
}
```

**Success (200)**
```json
{
  "message": "Password changed successfully."
}
```

**Errors**
- `400` - missing/invalid input
- `401` - invalid token or current password is wrong

---

### `POST /api/Auth/forgot-password/request`

Sends password reset code using provider selected through DI.

**Request Body**
```json
{
  "providerName": "Email|Phone",
  "destination": "email@domain.com OR phone-number"
}
```

**Success (200)**
```json
{
  "message": "Password reset code sent successfully."
}
```

**Errors**
- `400` - invalid provider/input
- `404` - user not found by destination

---

### `POST /api/Auth/forgot-password/reset`

Resets password using code sent in previous step.

**Request Body**
```json
{
  "providerName": "Email|Phone",
  "destination": "email@domain.com OR phone-number",
  "code": "123456",
  "newPassword": "new-password"
}
```

**Success (200)**
```json
{
  "message": "Password reset successfully."
}
```

**Errors**
- `400` - missing/invalid input
- `401` - invalid or expired reset code

---

### `POST /api/Auth/send-email-otp`

Sends OTP to email (10-minute expiration).

**Success (200)**
```json
{
  "message": "OTP has been sent to your email."
}
```

**Errors**
- `400` - invalid email input
- `404` - no account found for this email

---

### `POST /api/Auth/verify-email-otp`

Verifies OTP and marks the user email as verified.

**Success (200)**
```json
{
  "message": "Email verified successfully."
}
```

**Errors**
- `400` - invalid input
- `400` - `{"message":"OTP expired."}`
- `400` - `{"message":"Invalid OTP."}`

---

## 2) Company Images

### `POST /api/CompanyImages/upload` (Authorized)

Uploads and compresses company image (target under 1 MB).

**Success (200)**
```json
{
  "id": 10,
  "imagePath": "/company-images/{userId}/{file}.jpg",
  "isPrimary": true
}
```

**Errors**
- `401` - invalid/missing token
- `403` - user is not a company account
- `400` - invalid/missing file
- `404` - user not found

---

## 3) Notifications

### `POST /api/Notifications/send` (Authorized)

Sends FCM notification and saves it in DB.

**Success (200)**
```json
{
  "message": "Notification sent successfully."
}
```

**Errors**
- `400` - target user has no FCM token
- `400` - Firebase not configured / FCM send failed

---

## 4) Product Assets

> Requires authenticated seller token and ownership of the target product.

### `POST /api/ProductAssets/{productId}/images/upload` (Authorized)

Uploads one image file for the product.

**Success (200)**
```json
{
  "id": 1,
  "productId": "product-id",
  "path": "/product-images/{productId}/{file}.png"
}
```

**Errors**
- `401` - invalid/missing token
- `403` - product is not owned by authenticated user
- `404` - product not found
- `400` - invalid/missing file

---

### `POST /api/ProductAssets/{productId}/documents/upload` (Authorized)

Uploads one document file for the product.

**Success (200)**
```json
{
  "id": 1,
  "productId": "product-id",
  "path": "/product-documents/{productId}/{file}.pdf"
}
```

**Errors**
- `401` - invalid/missing token
- `403` - product is not owned by authenticated user
- `404` - product not found
- `400` - invalid/missing file

---

## 5) Products

### `POST /api/Products` (Authorized)

Creates a product for authenticated company user.

**Content-Type**: `multipart/form-data`
**Form fields (minimal):** `nameEn`, `usdPrice`, `quantity`, `productTypeName`, `unitName`, `originCountryName`, `destinationCountryName`, `loadingPortName`, `arrivalPortName`
**Optional video fields:** `productVideoFile`, `videoDurationSeconds` (must be 1-20 when video provided)
**Optional discount fields:** `discountPercentage`, `discountDays` (days count instead of start/end dates)

**Success (200)**
```json
{
  "productId": "guid",
  "ownerId": "guid",
  "nameEn": "Product A",
  "usdPrice": 120.50,
  "quantity": 100,
  "productType": "Retail",
  "unit": "Kilogram",
  "originCountry": "Egypt",
  "destinationCountry": "United Arab Emirates",
  "loadingPort": "Alexandria",
  "arrivalPort": "Jebel Ali",
  "videoPath": "/product-videos/abc123.mp4",
  "videoDurationSeconds": 20
}
```

**Errors**
- `400` - invalid input/validation rules
- `401` - invalid token
- `403` - forbidden by business rule
- `404` - lookup value not found (type/unit/country/port)

---

## 6) Offers

### `POST /api/Offers/OfferOnRequests` (Authorized)

Creates a new offer from authenticated user to another user.
Country and port are sent as strings and mapped internally to FK ids.

**Request Body**
```json
{
  "toUserId": "guid",
  "countryName": "Egypt",
  "portName": "Alexandria",
  "deliveryWindow": "7 days",
  "productId": "product-guid",
  "requestedQuantity": 1000,
  "unitName": "Kilogram",
  "unitPrice": 10.5,
  "totalPrice": 9800.0
}
```

**Success (200)**
```json
{
  "id": 1,
  "fromUserId": "guid",
  "toUserId": "guid",
  "country": "Egypt",
  "port": "Alexandria",
  "deliveryWindow": "7 days",
  "productId": "product-guid",
  "requestedQuantity": 1000,
  "unit": "Kilogram",
  "unitPrice": 10.5,
  "totalPrice": 10500.0,
  "statusId": 1
}
```

**Errors**
- `400` - invalid input
- `401` - invalid token
- `404` - user/country/port/unit not found

---

### `POST /api/Offers/OfferOnNegotiable` (Authorized)

Creates a negotiable offer for a specific product.

**Request Body**
```json
{
  "toUserId": "guid",
  "productId": "product-guid",
  "offeredPrice": 900.0,
  "unitName": "Kilogram",
  "baseUnitPrice": 12.5,
  "requestedQuantity": 100
}
```

**Success (200)**
```json
{
  "id": 1,
  "productId": "guid",
  "fromUserId": "guid",
  "toUserId": "guid",
  "offeredPrice": 900.0,
  "unit": "Kilogram",
  "baseUnitPrice": 12.5,
  "requestedQuantity": 100
}
```

---

### `GET /api/Offers/OfferOnNegotiable` (Authorized)

Returns negotiable offers. Optional filter by `productId`.

**Query**
- `productId` (optional, guid)


## 7) Company Licence

### `POST /api/CompanyLicence/upload` (Authorized, multipart/form-data)

Uploads/updates licence file for authenticated company user.

**Form Data**
- `file`: licence file

**Success (200)**
```json
{
  "path": "/company-licences/{userId}/{fileName}.ext"
}
```

**Errors**
- `400` - invalid/missing file
- `401` - invalid token
- `403` - user is not company role
- `404` - user not found

---

## 8) Addresses

### `POST /api/Addresses` (Authorized)

Adds address for currently authenticated user.

**Request Body**
```json
{
  "cityId": "guid",
  "addressLine1": "Street, Building, Floor",
  "addressLine2": "optional details"
}
```

**Success (200)**
```json
{
  "id": "guid",
  "userId": "guid",
  "cityId": "guid",
  "addressLine1": "Street, Building, Floor",
  "addressLine2": "optional details"
}
```

**Errors**
- `400` - invalid input
- `401` - invalid token
- `404` - user/city not found

---

## 9) Admin Company Approval

> Requires admin role token.

### `GET /api/admin/companies/pending`

Returns pending company accounts with license and images.

**Success (200)**
```json
[
  {
    "id": "company-user-id",
    "fullName": "Company Owner",
    "email": "company@email.com",
    "phoneNumber": "optional",
    "landNumber": "optional",
    "licencePath": "/licenses/lic.jpg",
    "images": [
      {
        "id": 1,
        "imagePath": "/company-images/...jpg",
        "isPrimary": true
      }
    ]
  }
]
```

**Errors**
- `401` - invalid/missing token
- `403` - token is not admin

---

### `POST /api/admin/companies/{companyUserId}/approve`

Approves company account and triggers background email + FCM notifications.

**Success (200)**
```json
{
  "message": "Company approved successfully."
}
```

**Errors**
- `404` - company user not found
- `400` - missing required company docs/images
- `401/403` - unauthorized/non-admin

---

## 10) Geo & International Shipping

### `GET /api/Geo/countries/{countryName}/ports`

Returns all ports inside the given country.

**Success (200)**
```json
{
  "country": "Egypt",
  "ports": [
    { "id": 1, "portNameEn": "Port Said", "unLocode": "EGPSD" }
  ]
}
```

**Errors**
- `400` - invalid country name
- `404` - country not found

---

### `POST /api/InternationalShipping/posts` (Authorized, supplier only)

Creates a new international shipping post.

**Request Body**
```json
{
  "fromCountryName": "Egypt",
  "fromPortName": "Port Said",
  "toCountryName": "United Arab Emirates",
  "toPortName": "Jebel Ali",
  "priceUsd": 1000.0,
  "shippingCostUsd": 200.0,
  "phoneNumber": "+20123456789",
  "container20ftPriceUsd": 1500.0,
  "container40ftPriceUsd": 2500.0
}
```

**Success (200)**
```json
{
  "id": 1,
  "fromCountry": "Egypt",
  "fromPort": "Port Said",
  "toCountry": "United Arab Emirates",
  "toPort": "Jebel Ali",
  "priceUsd": 1000.0,
  "shippingCostUsd": 200.0,
  "phoneNumber": "+20123456789",
  "container20ftPriceUsd": 1500.0,
  "container40ftPriceUsd": 2500.0,
  "publisherUserId": "guid"
}
```

**Errors**
- `400` - invalid input
- `401` - invalid token
- `403` - non-supplier user
- `404` - country/port/publisher not found

---

### `GET /api/InternationalShipping/search`

Searches shipping posts by route (country/port names).

**Query Parameters (optional)**
- `fromCountryName`
- `fromPortName`
- `toCountryName`
- `toPortName`

**Success (200)**
```json
[
  {
    "id": 1,
    "fromCountry": "Egypt",
    "fromPort": "Port Said",
    "toCountry": "United Arab Emirates",
    "toPort": "Jebel Ali",
    "priceUsd": 1000.0,
    "shippingCostUsd": 200.0,
    "phoneNumber": "+20123456789",
    "container20ftPriceUsd": 1500.0,
    "container40ftPriceUsd": 2500.0
  }
]
```

---

**Caching**
- This GET endpoint uses in-memory caching for repeated identical query parameters.

## 11) Carts

### `POST /api/Carts/items` (Authorized)

Adds product item to the authenticated user's cart.

**Request Body**
```json
{
  "productId": "guid",
  "quantity": 2.5,
  "unitName": "Kilogram"
}
```

**Success (200)**
```json
{
  "cartId": "guid",
  "cartItemId": 1,
  "productId": "guid",
  "unit": "Kilogram",
  "quantity": 2.5,
  "unitPriceUsd": 99.5,
  "totalPriceUsd": 248.75
}
```

**Errors**
- `400` invalid input / invalid unit conversion
- `401` invalid token
- `404` product/user/unit not found

---

### `GET /api/Carts/me` (Authorized)

Returns the authenticated user's cart with items.

**Success (200)**
```json
{
  "cartId": "guid",
  "items": [
    {
      "id": 1,
      "productId": "guid",
      "productName": "Integration Product",
      "quantity": 2.5,
      "unit": "Kilogram",
      "unitPriceUsd": 99.5,
      "totalPriceUsd": 248.75
    }
  ]
}
```

---

**Caching**
- This GET endpoint uses in-memory caching per authenticated user.
- `GET /api/Geo/countries/{countryName}/ports` also uses in-memory caching per country name.

## 12) Categories (Admin)

### `POST /api/Categories` (Authorized Admin)

Creates a category.

**Request Body**
```json
{
  "nameEn": "Coffee",
  "imgPath": "/images/categories/coffee.jpg"
}
```

### `PUT /api/Categories/{categoryId}` (Authorized Admin)

Updates category name and optional image path.

**Request Body**
```json
{
  "nameEn": "Coffee Beans",
  "imgPath": "/images/categories/coffee-beans.jpg"
}
```

### `POST /api/Categories/{categoryId}/image/upload` (Authorized Admin, multipart/form-data)

Uploads and compresses category image (target under ~600KB, jpg output).

**Form Data**
- `file`

## Quick Summary

- Authentication returns JWT only when business rules pass (verification + approval checks).
- Company accounts are blocked from login until admin approval.
- OTP flow:
  1. send OTP
  2. verify OTP
  3. login succeeds after verification
- Company image upload returns stored image metadata.
- Product supports one-to-many uploads for both images and documents.
- Company login response now includes `companyName` and `licenseNumber`.
- Password reset flow supports provider-based routing (`Email` or `Phone`) via DI.
- Address endpoint allows adding address for authenticated user.
- Notifications endpoint returns success message or a `400` with reason.
