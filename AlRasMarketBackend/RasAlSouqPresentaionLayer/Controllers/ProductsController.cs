using System.Globalization;
using System.Security.Claims;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Endpoints for product operations.
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class ProductsController(
    IProductsAppService productsAppService,
    IWebHostEnvironment environment,
    ILogger<ProductsController> logger) : ControllerBase
{
    private readonly IProductsAppService _productsAppService = productsAppService;
    private readonly IWebHostEnvironment _environment = environment;
    private readonly ILogger<ProductsController> _logger = logger;

    /// <summary>
    /// Returns all products and shipping posts owned by the authenticated user.
    /// Response contains text values only (no ids or foreign keys).
    /// </summary>
    [HttpGet("my-listings")]
    [ProducesResponseType(typeof(MyListingsResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetMyListings(CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _productsAppService.GetMyListingsAsync(userId, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Gets public products that have a category assigned (CategoryId is not null), paginated.
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> GetAll([FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await _productsAppService.GetAllAsync(new GetProductsInput
            {
                Page = page,
                PageSize = pageSize
            }, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Gets products filtered by product type name.
    /// </summary>
    [HttpGet("by-type/{productTypeName}")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetByType([FromRoute] string productTypeName, [FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await _productsAppService.GetByTypeAsync(new GetProductsByTypeInput
            {
                ProductTypeName = productTypeName,
                Page = page,
                PageSize = pageSize
            }, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Gets products filtered by category id.
    /// </summary>
    [HttpGet("by-category/{categoryId:int}")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetByCategory(
        [FromRoute] int categoryId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        if (categoryId < byte.MinValue || categoryId > byte.MaxValue)
        {
            return BadRequest(new { message = "Invalid category id." });
        }

        try
        {
            var result = await _productsAppService.GetByCategoryAsync(new GetProductsByCategoryInput
            {
                CategoryId = (byte)categoryId,
                Page = page,
                PageSize = pageSize
            }, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Gets all featured products.
    /// </summary>
    [HttpGet("featured")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> GetFeatured([FromQuery] int page = 1, [FromQuery] int pageSize = 20, CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await _productsAppService.GetFeaturedAsync(new GetProductsInput
            {
                Page = page,
                PageSize = pageSize
            }, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Searches active products by name, description, category, or product type.
    /// </summary>
    [HttpGet("search")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Search(
        [FromQuery] string q,
        [FromQuery] string? query,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var searcherUserId = User.FindFirst("EntityId")?.Value
                ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            var result = await _productsAppService.SearchAsync(new SearchProductsInput
            {
                Query = !string.IsNullOrWhiteSpace(q) ? q : query ?? string.Empty,
                Page = page,
                PageSize = pageSize,
                SearcherUserId = searcherUserId
            }, cancellationToken);

            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Fast autocomplete suggestions (Meilisearch when enabled; SQL name index fallback).
    /// </summary>
    [HttpGet("search-suggest")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> SuggestSearch(
        [FromQuery] string q,
        [FromQuery] string? query,
        [FromQuery] int limit = 8,
        CancellationToken cancellationToken = default)
    {
        var text = !string.IsNullOrWhiteSpace(q) ? q : query ?? string.Empty;
        var result = await _productsAppService.SuggestSearchAsync(text, limit, cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Returns all active product names for client-side search autocomplete.
    /// </summary>
    [HttpGet("search-names")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSearchNames(CancellationToken cancellationToken = default)
    {
        var result = await _productsAppService.GetSearchNameIndexAsync(cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Gets a public product by its unique product code (e.g. RS4K9M2P7Q).
    /// </summary>
    [HttpGet("by-code/{productCode}")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetByCode(
        [FromRoute] string productCode,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await _productsAppService.GetByCodeAsync(productCode, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Gets a public product by its id (GUID).
    /// </summary>
    [HttpGet("{productId:guid}")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(
        [FromRoute] Guid productId,
        [FromQuery] bool asRetail = false,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await _productsAppService.GetByIdAsync(
                productId.ToString("D"),
                asRetail,
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Increases product views count by one.
    /// </summary>
    [HttpPost("{productId}/increase-view")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> IncreaseView([FromRoute] string productId, CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await _productsAppService.IncreaseViewsAsync(productId, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Visual search: Image → CLIP → Qdrant → matching catalog products.
    /// </summary>
    [HttpPost("detect-by-image")]
    [AllowAnonymous]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> DetectByImage([FromForm] DetectProductsByImageRequest request, CancellationToken cancellationToken = default)
    {
        if (request.File is null || request.File.Length == 0)
        {
            return BadRequest(new { message = "Image file is required." });
        }

        var extension = Path.GetExtension(request.File.FileName).ToLowerInvariant();
        var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        if (!allowed.Contains(extension))
        {
            return BadRequest(new { message = "Unsupported image format. Allowed: .jpg, .jpeg, .png, .webp" });
        }

        try
        {
            await using var stream = request.File.OpenReadStream();
            var result = await _productsAppService.DetectProductsFromImageAsync(stream, request.File.FileName, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Creates a new product for authenticated company account.
    /// ProductTypeName and UnitName are mapped to their FK ids internally.
    /// </summary>
    [HttpPost]
    [Consumes("multipart/form-data", "application/x-www-form-urlencoded")]
    [RequestSizeLimit(50 * 1024 * 1024)]
    public async Task<IActionResult> Create([FromForm] CreateProductRequest request, CancellationToken cancellationToken = default)
    {
        //get the user id from token
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        ApplyFormFieldAliases(Request, request);

        try
        {
            var result = await _productsAppService.CreateAsync(
                MapProductFormRequest(request, userId),
                cancellationToken);

            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Create product validation failed for user {UserId}", userId);
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            _logger.LogWarning(ex, "Create product not found for user {UserId}", userId);
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Create product forbidden for user {UserId}", userId);
            return Forbid();
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogError(ex, "Create product failed (InvalidOperation) for user {UserId}", userId);
            return BadRequest(new { message = ex.Message });
        }
        catch (DbUpdateException ex)
        {
            _logger.LogError(ex, "Create product DB update failed for user {UserId}", userId);
            return BadRequest(new { message = $"Product could not be saved: {ex.InnerException?.Message ?? ex.Message}" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Create product unexpected failure for user {UserId}", userId);
            return StatusCode(StatusCodes.Status500InternalServerError, new { message = "Product could not be saved." });
        }
    }

    /// <summary>
    /// Marks the product ready for admin review after media (images/videos) uploads finish.
    /// Until this is called, the ad stays hidden from the admin pending queues.
    /// </summary>
    [HttpPost("{productId}/submit-for-review")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SubmitForReview(
        [FromRoute] string productId,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _productsAppService.SubmitForAdminReviewAsync(
                productId,
                userId,
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Deletes a product. Company owners can delete their own products; admins can delete any.
    /// </summary>
    [HttpDelete("{productId}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete([FromRoute] string productId, CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        var webRoot = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");

        try
        {
            var result = await _productsAppService.DeleteAsync(
                new DeleteProductInput
                {
                    ProductId = productId,
                    UserId = userId,
                    WebRootPath = webRoot
                },
                cancellationToken);

            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    /// <summary>
    /// يوقف الإعلان (isActive=false) أو يعيد تنشيطه (isActive=true). للمورد صاحب الإعلان فقط، وبعد موافقة الأدمن.
    /// </summary>
    [HttpPatch("{productId}/listing-status")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetListingStatus(
        [FromRoute] string productId,
        [FromBody] SetProductListingStatusRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _productsAppService.SetListingStatusAsync(
                new SetProductListingStatusInput
                {
                    ProductId = productId,
                    OwnerId = userId,
                    IsActive = request.IsActive
                },
                cancellationToken);

            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    /// <summary>
    /// Marks the listing sold out (quantity = 0). Owner only.
    /// </summary>
    [HttpPatch("{productId}/sold-out")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> MarkSoldOut(
        [FromRoute] string productId,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _productsAppService.MarkSoldOutAsync(productId, userId, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    /// <summary>
    /// Updates an existing product. Uses the same form fields as create.
    /// </summary>
    [HttpPut("{productId}")]
    [Consumes("multipart/form-data", "application/x-www-form-urlencoded")]
    [RequestSizeLimit(50 * 1024 * 1024)]
    public async Task<IActionResult> Update(
        [FromRoute] string productId,
        [FromForm] CreateProductRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        ApplyFormFieldAliases(Request, request);

        try
        {
            var result = await _productsAppService.UpdateAsync(
                MapUpdateProductFormRequest(productId, request, userId),
                cancellationToken);

            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    private CreateProductInput MapProductFormRequest(CreateProductRequest request, string ownerId)
    {
        var webRoot = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        return MapProductFormCore(request, ownerId, webRoot);
    }

    private UpdateProductInput MapUpdateProductFormRequest(
        string productId,
        CreateProductRequest request,
        string ownerId)
    {
        var webRoot = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        var form = MapProductFormCore(request, ownerId, webRoot);
        return new UpdateProductInput
        {
            ProductId = productId,
            OwnerId = form.OwnerId,
            NameEn = form.NameEn,
            CreatedLanguage = form.CreatedLanguage,
            USDPrice = form.USDPrice,
            Currency = form.Currency,
            Quantity = form.Quantity,
            DescriptionEn = form.DescriptionEn,
            ProductTypeName = form.ProductTypeName,
            ProductType = form.ProductType,
            UnitName = form.UnitName,
            OriginCountryName = form.OriginCountryName,
            DestinationCountryName = form.DestinationCountryName,
            LoadingPortName = form.LoadingPortName,
            ArrivalPortName = form.ArrivalPortName,
            CategoryId = form.CategoryId,
            CategoryName = form.CategoryName,
            Category = form.Category,
            Categories = form.Categories,
            MinimumOrderQuantity = form.MinimumOrderQuantity,
            MaximumOrderQuantity = form.MaximumOrderQuantity,
            Status = form.Status,
            DiscountPercentage = form.DiscountPercentage,
            DiscountDays = form.DiscountDays,
            ShippingDescriptionEn = form.ShippingDescriptionEn,
            SupplierNotesEn = form.SupplierNotesEn,
            Packaging = form.Packaging,
            PackagingDetails = form.PackagingDetails,
            Negotiable = form.Negotiable,
            ProductVideoFile = form.ProductVideoFile,
            VideoDurationSeconds = form.VideoDurationSeconds,
            ShippingDuration = form.ShippingDuration,
            OfferDuration = form.OfferDuration,
            AddressId = form.AddressId,
            WebRootPath = form.WebRootPath,
            RetailPrice = form.RetailPrice,
            RetailUnitName = form.RetailUnitName,
            RetailQuantity = form.RetailQuantity,
            EnableRetailPricing = form.EnableRetailPricing,
            RetailPackaging = form.RetailPackaging,
            RetailPackagingDetails = form.RetailPackagingDetails,
            RetailDescriptionEn = form.RetailDescriptionEn,
            RequestTypeName = form.RequestTypeName,
            RequestTypeId = form.RequestTypeId,
            BookingPriceTypeName = form.BookingPriceTypeName,
            BookingPriceTypeId = form.BookingPriceTypeId
        };
    }

    private static CreateProductInput MapProductFormCore(
        CreateProductRequest request,
        string ownerId,
        string webRootPath) =>
        new()
        {
            OwnerId = ownerId,
            NameEn = request.NameEn,
            CreatedLanguage = request.CreatedLanguage,
            USDPrice = request.USDPrice,
            Currency = request.Currency,
            Quantity = request.Quantity,
            DescriptionEn = request.DescriptionEn,
            ProductTypeName = request.ProductTypeName,
            ProductType = request.ProductType,
            UnitName = request.UnitName,
            OriginCountryName = request.OriginCountryName,
            DestinationCountryName = request.DestinationCountryName,
            LoadingPortName = request.LoadingPortName,
            ArrivalPortName = request.ArrivalPortName,
            CategoryId = request.CategoryId,
            CategoryName = request.CategoryName,
            Category = request.Category,
            Categories = request.Categories,
            MinimumOrderQuantity = request.MinimumOrderQuantity,
            MaximumOrderQuantity = request.MaximumOrderQuantity,
            Status = request.Status,
            DiscountPercentage = request.DiscountPercentage,
            DiscountDays = request.DiscountDays,
            ShippingDescriptionEn = request.ShippingDescriptionEn,
            SupplierNotesEn = request.SupplierNotesEn,
            Packaging = request.Packaging,
            PackagingDetails = request.PackagingDetails,
            Negotiable = request.Negotiable,
            ProductVideoFile = request.ProductVideoFile,
            VideoDurationSeconds = request.VideoDurationSeconds,
            ShippingDuration = request.ShippingDuration,
            OfferDuration = request.OfferDuration,
            AddressId = request.AddressId,
            WebRootPath = webRootPath,
            RetailPrice = request.RetailPrice,
            RetailUnitName = request.RetailUnitName,
            RetailQuantity = request.RetailQuantity,
            EnableRetailPricing = request.EnableRetailPricing,
            RetailPackaging = request.RetailPackaging,
            RetailPackagingDetails = request.RetailPackagingDetails,
            RetailDescriptionEn = request.RetailDescriptionEn,
            RequestTypeName = request.RequestTypeName,
            RequestTypeId = request.RequestTypeId,
            BookingPriceTypeName = request.BookingPriceTypeName,
            BookingPriceTypeId = request.BookingPriceTypeId,
            DraftImagePaths = ParseDraftImagePaths(request.DraftImagePaths, request.DraftImagePathsCsv),
            DraftVideoPath = request.DraftVideoPath,
            DraftVideoDurationSeconds = request.DraftVideoDurationSeconds
        };

    private static List<string>? ParseDraftImagePaths(List<string>? paths, string? csv)
    {
        var list = new List<string>();
        if (paths is { Count: > 0 })
        {
            list.AddRange(paths.Where(p => !string.IsNullOrWhiteSpace(p)).Select(p => p.Trim()));
        }

        if (!string.IsNullOrWhiteSpace(csv))
        {
            list.AddRange(
                csv.Split([',', ';'], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));
        }

        return list.Count == 0
            ? null
            : list.Distinct(StringComparer.OrdinalIgnoreCase).ToList();
    }

    private static void ApplyFormFieldAliases(HttpRequest httpRequest, CreateProductRequest request)
    {
        if (!httpRequest.HasFormContentType)
        {
            return;
        }

        var form = httpRequest.Form;

        if (request.USDPrice <= 0)
        {
            request.USDPrice = ReadFormDecimal(
                form,
                "usdPrice",
                "usd_price",
                "USDPrice",
                "price");
        }

        if (request.Quantity <= 0)
        {
            request.Quantity = ReadFormLong(form, "quantity", "Quantity");
        }

        request.NameEn ??= ReadFormString(form, "nameEn", "name_en", "NameEn", "name");
        request.DescriptionEn ??= ReadFormString(form, "descriptionEn", "description_en", "DescriptionEn", "description");
        request.ProductTypeName = ReadFormString(form, "productTypeName", "product_type_name", "ProductTypeName", "productType", "product_type")
            ?? request.ProductTypeName;
        request.ProductType ??= ReadFormString(form, "productType", "product_type");
        request.UnitName = ReadFormString(form, "unitName", "unit_name", "UnitName", "unit")
            ?? request.UnitName;
        request.CategoryId ??= ReadFormString(form, "categoryId", "category_id", "CategoryId", "category", "categories");
        request.CategoryName ??= ReadFormString(form, "categoryName", "category_name", "CategoryName");
        request.OriginCountryName ??= ReadFormString(form, "originCountryName", "origin_country_name", "OriginCountryName");
        request.DestinationCountryName ??= ReadFormString(form, "destinationCountryName", "destination_country_name", "DestinationCountryName");
        request.LoadingPortName ??= ReadFormString(form, "loadingPortName", "loading_port_name", "LoadingPortName");
        request.ArrivalPortName ??= ReadFormString(form, "arrivalPortName", "arrival_port_name", "ArrivalPortName");
        if (string.IsNullOrWhiteSpace(request.Currency))
        {
            request.Currency = ReadFormString(form, "currency", "Currency");
        }
        request.AddressId ??= ReadFormString(form, "addressId", "AddressId", "address_id");

        if (request.RetailPrice is null or <= 0)
        {
            var retailPrice = ReadFormDecimal(
                form,
                "retailPrice",
                "retail_price",
                "RetailPrice");
            if (retailPrice > 0)
            {
                request.RetailPrice = retailPrice;
            }
        }

        request.RetailUnitName ??= ReadFormString(
            form,
            "retailUnitName",
            "retail_unit_name",
            "RetailUnitName",
            "retailUnit",
            "retail_unit");

        if (request.RetailQuantity is null or <= 0)
        {
            var retailQuantity = ReadFormLong(
                form,
                "retailQuantity",
                "retail_quantity",
                "RetailQuantity");
            if (retailQuantity > 0)
            {
                request.RetailQuantity = retailQuantity;
            }
        }

        request.EnableRetailPricing ??= ReadFormBool(
            form,
            "enableRetailPricing",
            "enable_retail_pricing",
            "EnableRetailPricing");

        request.RetailDescriptionEn ??= ReadFormString(
            form,
            "retailDescriptionEn",
            "retail_description_en",
            "RetailDescriptionEn",
            "retailDescription",
            "retail_description",
            "retailSpecifications",
            "retail_specifications");

        if (request.RetailPackaging is null or 0)
        {
            var retailPackaging = ReadFormLong(
                form,
                "retailPackaging",
                "retail_packaging",
                "RetailPackaging");
            if (retailPackaging is >= 1 and <= 255)
            {
                request.RetailPackaging = (byte)retailPackaging;
            }
        }

        request.RetailPackagingDetails ??= ReadFormString(
            form,
            "retailPackagingDetails",
            "retail_packaging_details",
            "RetailPackagingDetails");

        request.RequestTypeName ??= ReadFormString(
            form,
            "requestTypeName",
            "request_type_name",
            "RequestTypeName");

        if (request.RequestTypeId is null)
        {
            var requestTypeIdText = ReadFormString(
                form,
                "requestTypeId",
                "request_type_id",
                "RequestTypeId");
            if (byte.TryParse(requestTypeIdText, NumberStyles.Integer, CultureInfo.InvariantCulture, out var requestTypeId))
            {
                request.RequestTypeId = requestTypeId;
            }
        }

        request.BookingPriceTypeName ??= ReadFormString(
            form,
            "bookingPriceTypeName",
            "booking_price_type_name",
            "BookingPriceTypeName");

        if (request.BookingPriceTypeId is null)
        {
            var bookingPriceTypeIdText = ReadFormString(
                form,
                "bookingPriceTypeId",
                "booking_price_type_id",
                "BookingPriceTypeId");
            if (byte.TryParse(
                    bookingPriceTypeIdText,
                    NumberStyles.Integer,
                    CultureInfo.InvariantCulture,
                    out var bookingPriceTypeId))
            {
                request.BookingPriceTypeId = bookingPriceTypeId;
            }
        }

        // Defensive: some clients used to send a free-text "Address" field.
        // If it is a GUID, treat it as AddressId.
        if (string.IsNullOrWhiteSpace(request.AddressId))
        {
            var addressRaw = ReadFormString(form, "Address", "address");
            if (!string.IsNullOrWhiteSpace(addressRaw) && Guid.TryParse(addressRaw, out _))
            {
                request.AddressId = addressRaw;
            }
        }
    }

    private static string? ReadFormString(IFormCollection form, params string[] keys)
    {
        foreach (var key in keys)
        {
            if (!form.TryGetValue(key, out var value))
            {
                continue;
            }

            var text = value.ToString().Trim();
            if (!string.IsNullOrWhiteSpace(text))
            {
                return text;
            }
        }

        return null;
    }

    private static bool? ReadFormBool(IFormCollection form, params string[] keys)
    {
        foreach (var key in keys)
        {
            if (!form.TryGetValue(key, out var value))
            {
                continue;
            }

            var text = value.ToString().Trim();
            if (bool.TryParse(text, out var parsed))
            {
                return parsed;
            }

            if (text is "1" or "yes" or "on")
            {
                return true;
            }

            if (text is "0" or "no" or "off")
            {
                return false;
            }
        }

        return null;
    }

    private static decimal ReadFormDecimal(IFormCollection form, params string[] keys)
    {
        foreach (var key in keys)
        {
            if (!form.TryGetValue(key, out var value))
            {
                continue;
            }

            var text = value.ToString().Trim();
            if (decimal.TryParse(text, NumberStyles.Any, CultureInfo.InvariantCulture, out var parsed) && parsed > 0)
            {
                return parsed;
            }

            if (decimal.TryParse(text, NumberStyles.Any, CultureInfo.CurrentCulture, out parsed) && parsed > 0)
            {
                return parsed;
            }
        }

        return 0m;
    }

    private static long ReadFormLong(IFormCollection form, params string[] keys)
    {
        foreach (var key in keys)
        {
            if (!form.TryGetValue(key, out var value))
            {
                continue;
            }

            var text = value.ToString().Trim();
            if (long.TryParse(text, NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed) && parsed > 0)
            {
                return parsed;
            }
        }

        return 0L;
    }
}

public sealed class CreateProductRequest
{
    public string? NameEn { get; set; }
    /// <summary>App UI language when creating the ad (<c>en</c> / <c>ar</c>).</summary>
    public string? CreatedLanguage { get; set; }
    public decimal USDPrice { get; set; }
    public long Quantity { get; set; }
    public string? DescriptionEn { get; set; }
    public string? ProductTypeName { get; set; }
    public string? ProductType { get; set; }
    public string UnitName { get; set; } = string.Empty;
    public string? OriginCountryName { get; set; }
    public string? DestinationCountryName { get; set; }
    public string? LoadingPortName { get; set; }
    public string? ArrivalPortName { get; set; }
    public string? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string? Category { get; set; }
    public string? Categories { get; set; }
    public int? MinimumOrderQuantity { get; set; }
    public int? MaximumOrderQuantity { get; set; }
    public byte? Status { get; set; }
    public byte? DiscountPercentage { get; set; }
    public short? DiscountDays { get; set; }
    public string? ShippingDescriptionEn { get; set; }
    public string? SupplierNotesEn { get; set; }
    public byte? Packaging { get; set; }
    public string? PackagingDetails { get; set; }
    public bool? Negotiable { get; set; }
    public string? Currency { get; set; }
    public IFormFile? ProductVideoFile { get; set; }
    public byte? VideoDurationSeconds { get; set; }
    public string? ShippingDuration { get; set; }
    public string? OfferDuration { get; set; }
    public string? AddressId { get; set; }
    public decimal? RetailPrice { get; set; }
    public string? RetailUnitName { get; set; }
    public long? RetailQuantity { get; set; }
    public bool? EnableRetailPricing { get; set; }
    public byte? RetailPackaging { get; set; }
    public string? RetailPackagingDetails { get; set; }
    public string? RetailDescriptionEn { get; set; }
    public string? RequestTypeName { get; set; }
    public byte? RequestTypeId { get; set; }
    public string? BookingPriceTypeName { get; set; }
    public byte? BookingPriceTypeId { get; set; }

    /// <summary>Repeated form keys or bound list of draft image paths already on R2.</summary>
    public List<string>? DraftImagePaths { get; set; }

    /// <summary>Comma-separated draft image paths (mobile-friendly single field).</summary>
    public string? DraftImagePathsCsv { get; set; }

    public string? DraftVideoPath { get; set; }
    public byte? DraftVideoDurationSeconds { get; set; }
}

public sealed class DetectProductsByImageRequest
{
    public IFormFile? File { get; set; }
}

public sealed class SetProductListingStatusRequest
{
    /// <summary>true = إعادة تنشيط، false = إيقاف مؤقت</summary>
    public bool IsActive { get; set; }
}
