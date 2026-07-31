using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.LoginServices.Dtos;
using DataLayer.Models;
using Microsoft.AspNetCore.Http;

namespace BusinessLayer.Interfaces;

public interface IAuthAppService
{
    Task<(string message, string userId, string? imgPath)> RegisterPersonAsync(RegisterPersonInput input, CancellationToken cancellationToken = default);
    Task<(string message, string userId, string? imgPath, bool isCustomer)> RegisterCompanyAsync(RegisterCompanyInput input, CancellationToken cancellationToken = default);
    Task<(string message, string userId, string? imgPath)> RegisterShippingCompanyAsync(RegisterShippingCompanyInput input, CancellationToken cancellationToken = default);
    Task<object> LoginAsync(LoginDtos.LoginRequest request, CancellationToken cancellationToken = default);
    Task SendEmailOtpAsync(string email, CancellationToken cancellationToken = default);
    Task<OtpVerificationStatus> VerifyEmailOtpAsync(string email, string otp, CancellationToken cancellationToken = default);
    Task<object> VerifyEmailOtpAndLoginAsync(string email, string otp, string? fcmToken = null, CancellationToken cancellationToken = default);
    Task UpdateFcmTokenAsync(string userId, string fcmToken, CancellationToken cancellationToken = default);
    Task ClearFcmTokenAsync(string userId, CancellationToken cancellationToken = default);
    Task<object> GetCompanyActivationStatusAsync(string email, string? fcmToken = null, CancellationToken cancellationToken = default);
    Task<object> GetAccountApprovalStatusAsync(string email, CancellationToken cancellationToken = default);
    Task<string> ChangePasswordAsync(string userId, string currentPassword, string newPassword, CancellationToken cancellationToken = default);
    Task<string> ForgotPasswordRequestAsync(string providerName, string destination, CancellationToken cancellationToken = default);
    Task<string> ForgotPasswordResetAsync(string providerName, string destination, string code, string newPassword, CancellationToken cancellationToken = default);
}

public interface IAccountDeletionAppService
{
    Task<string> DeleteAccountAsync(string userId, string password, CancellationToken cancellationToken = default);
    Task<string> DeleteUserByAdminAsync(string userId, CancellationToken cancellationToken = default);
}

public interface IAdminCompaniesAppService
{
    Task<object> GetPendingCompaniesAsync(CancellationToken cancellationToken = default);
    Task<string> ApproveCompanyAsync(string companyUserId, CancellationToken cancellationToken = default);
    Task<string> RejectCompanyAsync(string companyUserId, AdminRejectCompanyRequest request, CancellationToken cancellationToken = default);
}

public interface IAdminGlobalSearchAppService
{
    Task<IReadOnlyList<AdminSearchSuggestionDto>> GetSuggestionsAsync(
        string? query,
        int limit = 8,
        CancellationToken cancellationToken = default);

    Task<AdminGlobalSearchResultDto> SearchAsync(
        string? query,
        CancellationToken cancellationToken = default);
}

public interface IAdminDashboardAppService
{
    Task<object> GetDashboardAsync(
        DateTime? createdFrom = null,
        DateTime? createdTo = null,
        CancellationToken cancellationToken = default);
}

public interface IProfileAppService
{
    Task<object> GetMyProfileAsync(string userId, CancellationToken cancellationToken = default);
    Task<object> UpdateMyProfileAsync(string userId, UpdateProfileInput input, CancellationToken cancellationToken = default);
    Task<object> UploadMyProfileImageAsync(
        string userId,
        UploadProfileImageInput input,
        CancellationToken cancellationToken = default);
}

public interface IUserIbanAppService
{
    Task<object> GetMyIbansAsync(string userId, CancellationToken cancellationToken = default);
    Task<object> AddMyIbanAsync(string userId, CreateUserIbanRequest input, CancellationToken cancellationToken = default);
}

public interface IWithdrawalRequestsAppService
{
    Task<object> GetMyWithdrawalRequestsAsync(string userId, CancellationToken cancellationToken = default);
    Task<object> CreateMyWithdrawalRequestAsync(string userId, CreateWithdrawalRequestInput input, CancellationToken cancellationToken = default);
}

public interface IAdminFinanceAppService
{
    Task<object> GetWithdrawalRequestsAsync(AdminGetWithdrawalRequestsInput input, CancellationToken cancellationToken = default);
    Task<object> GetCompanyFinanceProfileAsync(string userId, CancellationToken cancellationToken = default);
    Task<object> GetCompanyBalanceStatementAsync(string userId, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<object> MarkWithdrawalPaidAsync(string adminUserId, string withdrawalRequestId, AdminMarkWithdrawalPaidInput input, CancellationToken cancellationToken = default);
}

public sealed class UpdateProfileInput
{
    public string? FullName { get; set; }
    public string? PhoneNumber { get; set; }
    public DateTime? BirthDate { get; set; }
    public string? CompanyName { get; set; }
    public string? CommercialRegister { get; set; }
    public string? TaxNumber { get; set; }
    public string? Website { get; set; }
    public string? LandNumber { get; set; }
}

public sealed class UploadProfileImageInput
{
    public required IFormFile File { get; set; }
    public required string WebRootPath { get; set; }
}

public interface IAdminUsersAppService
{
    Task<object> GetUsersAsync(
        int page,
        int pageSize,
        byte? roleId,
        string? search,
        string? status,
        DateTime? joinedFrom,
        DateTime? joinedTo,
        CancellationToken cancellationToken = default);

    Task<AdminUserDetailDto> GetUserByIdAsync(string userId, CancellationToken cancellationToken = default);

    Task<object> SetUserActiveAsync(string userId, bool isActive, CancellationToken cancellationToken = default);

    Task<object> DeleteUserAsync(string userId, CancellationToken cancellationToken = default);
}

public interface IAdminOrdersAppService
{
    Task<object> GetOrdersAsync(
        int page,
        int pageSize,
        byte? statusId,
        byte? productTypeId,
        byte? excludeProductTypeId,
        string? productId,
        string? search,
        DateTime? createdFrom,
        DateTime? createdTo,
        string? offerReview = null,
        string? orderChannel = null,
        CancellationToken cancellationToken = default);

    Task<AdminOrderStatsDto> GetOrderStatsAsync(CancellationToken cancellationToken = default);

    Task<AdminOrderListItemDto> GetOrderByIdAsync(long orderId, CancellationToken cancellationToken = default);
    Task<object> UpdateOrderStatusAsync(string adminUserId, long orderId, byte statusId, CancellationToken cancellationToken = default);
    Task<object> ApproveRequestOfferAsync(string adminUserId, long orderId, CancellationToken cancellationToken = default);
    Task<object> RejectRequestOfferAsync(string adminUserId, long orderId, CancellationToken cancellationToken = default);
    Task<object> SetCustomOrderStatusAsync(
        string adminUserId,
        long orderId,
        string statusNameEn,
        string statusNameAr,
        CancellationToken cancellationToken = default);
    Task<object> MarkOrderReceivedAsync(
        string adminUserId,
        long orderId,
        CancellationToken cancellationToken = default);
    Task<object> RespondToReturnAsync(
        string adminUserId,
        long orderId,
        string response,
        bool approved,
        CancellationToken cancellationToken = default);
}

public interface IAdminShippingAppService
{
    Task<object> GetProvidersAsync(int page, int pageSize, string? search, CancellationToken cancellationToken = default);
    Task<object> GetProviderDetailAsync(string providerUserId, CancellationToken cancellationToken = default);
    Task<object> SetProviderActiveAsync(string providerUserId, bool isActive, CancellationToken cancellationToken = default);
    Task<object> CreateProviderAsync(AdminCreateShippingProviderInput input, CancellationToken cancellationToken = default);
    Task<object> UpdateProviderAsync(string providerUserId, AdminUpdateShippingProviderInput input, CancellationToken cancellationToken = default);
    Task<object> UploadProviderImageAsync(AdminUploadShippingProviderImageInput input, CancellationToken cancellationToken = default);
    Task<object> DeleteProviderAsync(string providerUserId, CancellationToken cancellationToken = default);
    Task<string> ApprovePostAsync(long postId, CancellationToken cancellationToken = default);
    Task<string> RejectPostAsync(long postId, string? reason, CancellationToken cancellationToken = default);
}

public interface IAdminNotificationsAppService
{
    Task<object> GetBroadcastHistoryAsync(
        int page,
        int pageSize,
        string? audience,
        CancellationToken cancellationToken = default);

    Task<object> QueueBroadcastAsync(
        AdminSendPushNotificationRequest request,
        Guid? adminUserId,
        CancellationToken cancellationToken = default);
}

public interface IAdminProductsAppService
{
    Task<AdminPagedResult<AdminProductListItemDto>> GetProductsAsync(
        int page,
        int pageSize,
        string? search,
        string? approval,
        byte? categoryId,
        byte? status,
        byte? productTypeId,
        byte? excludeProductTypeId,
        DateTime? createdFrom,
        DateTime? createdTo,
        bool? hasPendingOffers = null,
        bool? editResubmitOnly = null,
        CancellationToken cancellationToken = default);

    Task<AdminProductStatsDto> GetProductStatsAsync(CancellationToken cancellationToken = default);

    /// <summary>Enqueue all product images for CLIP reindex into Qdrant.</summary>
    Task<object> ReindexImageVectorsAsync(CancellationToken cancellationToken = default);

    Task<string> ApproveProductAsync(
        string productId,
        AdminRejectProductRequest? request = null,
        CancellationToken cancellationToken = default);

    Task<string> RejectProductAsync(
        string productId,
        AdminRejectProductRequest request,
        CancellationToken cancellationToken = default);

    Task<AdminProductDetailDto> GetProductByIdAsync(string productId, CancellationToken cancellationToken = default);

    Task<object> UpdateProductAsync(
        string productId,
        AdminUpdateProductRequest request,
        CancellationToken cancellationToken = default);

    Task<AdminProductLookupsDto> GetLookupsAsync(CancellationToken cancellationToken = default);

    Task<string> DeleteProductImageAsync(
        string productId,
        long imageId,
        string? webRootPath,
        CancellationToken cancellationToken = default);

    Task<string> DeleteProductVideoAsync(
        string productId,
        string videoPath,
        string? webRootPath,
        CancellationToken cancellationToken = default);

    Task<string> DeleteProductAsync(
        string productId,
        string adminUserId,
        string? webRootPath,
        CancellationToken cancellationToken = default);
}

public interface ICompanyImagesAppService
{
    Task<object> UploadAsync(UploadCompanyImageInput input, CancellationToken cancellationToken = default);
}

public interface INotificationsAppService
{
    Task<string> SendAsync(SendNotificationInput input, CancellationToken cancellationToken = default);
    Task<object> GetMineAsync(string userId, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<object> GetUnreadCountAsync(string userId, CancellationToken cancellationToken = default);
    Task<object> MarkReadAsync(string userId, string notificationId, CancellationToken cancellationToken = default);
    Task<object> MarkAllReadAsync(string userId, CancellationToken cancellationToken = default);
}

public interface IProductAssetsAppService
{
    Task<object> UploadImageAsync(UploadProductImageInput input, CancellationToken cancellationToken = default);
    Task<object> UploadDocumentAsync(UploadProductDocumentInput input, CancellationToken cancellationToken = default);
    Task<object> UploadVideoAsync(UploadProductVideoInput input, CancellationToken cancellationToken = default);
    Task<object> PresignImageUploadAsync(PresignProductImageInput input, CancellationToken cancellationToken = default);
    Task<object> ConfirmImageUploadAsync(ConfirmProductImageInput input, CancellationToken cancellationToken = default);
    Task<object> PresignDocumentUploadAsync(PresignProductDocumentInput input, CancellationToken cancellationToken = default);
    Task<object> ConfirmDocumentUploadAsync(ConfirmProductDocumentInput input, CancellationToken cancellationToken = default);
    Task<object> PresignVideoUploadAsync(PresignProductVideoInput input, CancellationToken cancellationToken = default);
    Task<object> ConfirmVideoUploadAsync(ConfirmProductVideoInput input, CancellationToken cancellationToken = default);

    /// <summary>
    /// Confirms many draft/final image paths (+ optional video) in one DB SaveChanges.
    /// </summary>
    Task<object> ConfirmProductAssetsBatchAsync(
        ConfirmProductAssetsBatchInput input,
        CancellationToken cancellationToken = default);

    Task<object> UploadOfferStagingImageAsync(UploadStagingAssetInput input, CancellationToken cancellationToken = default);
    Task<object> UploadOfferStagingDocumentAsync(UploadStagingAssetInput input, CancellationToken cancellationToken = default);
    Task<object> UploadOfferStagingVideoAsync(UploadStagingAssetInput input, CancellationToken cancellationToken = default);
    Task<string> DeleteImageAsync(long imageId, string ownerId, string? webRootPath, bool allowAdminAccess, CancellationToken cancellationToken = default);
    Task<string> DeleteImageByPathAsync(string productId, string imagePath, string ownerId, string? webRootPath, CancellationToken cancellationToken = default);
    Task<string> DeleteVideoByPathAsync(
        string productId,
        string videoPath,
        string ownerId,
        string? webRootPath,
        bool allowAdminAccess,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Issues a short-lived presigned PUT URL for a draft image (no product required).
    /// Path: product-images/drafts/{userId}/{guid}.jpg
    /// </summary>
    Task<object> PresignDraftImageUploadAsync(PresignDraftImageInput input, CancellationToken cancellationToken = default);

    /// <summary>
    /// Issues a short-lived presigned PUT URL for a draft video (no product required).
    /// Path: product-videos/drafts/{userId}/{guid}{ext}
    /// </summary>
    Task<object> PresignDraftVideoUploadAsync(PresignDraftVideoInput input, CancellationToken cancellationToken = default);

    /// <summary>
    /// Deletes a draft object. Only allowed when the path contains /drafts/{userId}/.
    /// </summary>
    Task DeleteDraftAsync(DeleteDraftInput input, CancellationToken cancellationToken = default);
}

public interface ICompanyLicenceAppService
{
    Task<object> UploadAsync(UploadCompanyLicenceInput input, CancellationToken cancellationToken = default);
}

public interface IProductsAppService
{
    Task<object> CreateAsync(CreateProductInput input, CancellationToken cancellationToken = default);
    Task<object> UpdateAsync(UpdateProductInput input, CancellationToken cancellationToken = default);
    /// <summary>
    /// Call after all images/videos/documents are uploaded so the ad appears on the admin dashboard.
    /// </summary>
    Task<object> SubmitForAdminReviewAsync(
        string productId,
        string ownerId,
        CancellationToken cancellationToken = default);
    Task<object> DeleteAsync(DeleteProductInput input, CancellationToken cancellationToken = default);
    Task<object> SetListingStatusAsync(
        SetProductListingStatusInput input,
        CancellationToken cancellationToken = default);
    Task<object> MarkSoldOutAsync(
        string productId,
        string ownerId,
        CancellationToken cancellationToken = default);
    Task<object> GetAllAsync(GetProductsInput input, CancellationToken cancellationToken = default);
    Task<object> GetByTypeAsync(GetProductsByTypeInput input, CancellationToken cancellationToken = default);
    Task<object> GetByCategoryAsync(GetProductsByCategoryInput input, CancellationToken cancellationToken = default);
    Task<object> GetFeaturedAsync(GetProductsInput input, CancellationToken cancellationToken = default);
    Task<object> SearchAsync(SearchProductsInput input, CancellationToken cancellationToken = default);
    Task<object> GetByCodeAsync(string productCode, CancellationToken cancellationToken = default);
    Task<object> GetByIdAsync(string productId, bool asRetail = false, CancellationToken cancellationToken = default);
    Task<object> GetSearchNameIndexAsync(CancellationToken cancellationToken = default);
    Task<object> IncreaseViewsAsync(string productId, CancellationToken cancellationToken = default);
    Task<object> SearchByThreeNamesAsync(string firstName, string secondName, string thirdName, CancellationToken cancellationToken = default);
    Task<object> SearchBySuggestedNamesAsync(IReadOnlyList<string> suggestedNames, CancellationToken cancellationToken = default);
    Task<object> DetectProductsFromImageAsync(Stream imageStream, string fileName, CancellationToken cancellationToken = default);
    Task<MyListingsResponse> GetMyListingsAsync(string ownerId, CancellationToken cancellationToken = default);
}

public interface IAddressesAppService
{
    Task<object> GetByUserAsync(string userId, CancellationToken cancellationToken = default);
    Task<object> AddAsync(AddAddressInput input, CancellationToken cancellationToken = default);
    Task<object> UpdateAsync(UpdateAddressInput input, CancellationToken cancellationToken = default);
    Task DeleteAsync(string userId, Guid addressId, CancellationToken cancellationToken = default);
}

public interface IOffersAppService
{
    Task<object> CreateAsync(CreateOfferInput input, CancellationToken cancellationToken = default);
    Task<object> GetOffersOnRequestsAsync(string? productId, CancellationToken cancellationToken = default);
    Task<object> CreateOfferOnNegotiableAsync(CreateOfferOnNegotiableInput input, CancellationToken cancellationToken = default);
    Task<object> GetOfferOnNegotiableAsync(string? productId, CancellationToken cancellationToken = default);
}

public interface IInternationalShippingAppService
{
    Task<object> CreatePostAsync(CreateInternationalShippingPostInput input, CancellationToken cancellationToken = default);
    Task<object> SearchAsync(SearchInternationalShippingInput input, CancellationToken cancellationToken = default);
    Task<object> GetPortsByCountryNameAsync(string countryName, CancellationToken cancellationToken = default);
}

public interface IShippingCompanyAppService
{
    Task<object> GetDashboardAsync(string userId, CancellationToken cancellationToken = default);
    Task<object> GetMyPostsAsync(string userId, CancellationToken cancellationToken = default);
    Task<object> CreatePostAsync(string userId, CreateInternationalShippingPostInput input, CancellationToken cancellationToken = default);
    Task<object> UpdatePostAsync(UpdateInternationalShippingPostInput input, CancellationToken cancellationToken = default);
    Task<object> DeletePostAsync(string userId, long postId, CancellationToken cancellationToken = default);
}

public interface ICartAppService
{
    Task<object> AddItemAsync(AddCartItemInput input, CancellationToken cancellationToken = default);
    Task<object> GetMyCartAsync(string userId, CancellationToken cancellationToken = default);
    Task<object> RemoveItemAsync(RemoveCartItemInput input, CancellationToken cancellationToken = default);
    Task<object> ReduceItemQuantityAsync(ReduceCartItemInput input, CancellationToken cancellationToken = default);
}

public interface ICategoriesAppService
{
    /// <summary>
    /// Visible categories for the mobile app (IsHide = false); backed by memory cache.
    /// </summary>
    Task<object> GetAllAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// All categories for admin management, including hidden ones.
    /// </summary>
    Task<object> GetAllForAdminAsync(string userId, CancellationToken cancellationToken = default);

    Task<object> CreateAsync(CreateCategoryInput input, CancellationToken cancellationToken = default);
    Task<object> UpdateAsync(UpdateCategoryInput input, CancellationToken cancellationToken = default);
    Task<object> SetHideAsync(SetCategoryHideInput input, CancellationToken cancellationToken = default);
    Task<object> UploadImageAsync(UploadCategoryImageInput input, CancellationToken cancellationToken = default);
    Task<object> DeleteAsync(DeleteCategoryInput input, CancellationToken cancellationToken = default);
}

public interface IHomeBannersAppService
{
    Task<object> CreateAsync(CreateHomeBannerInput input, CancellationToken cancellationToken = default);
    Task<object> GetAllAsync(CancellationToken cancellationToken = default);
    Task<object> UpdateAsync(UpdateHomeBannerInput input, CancellationToken cancellationToken = default);
    Task<object> DeleteAsync(DeleteHomeBannerInput input, CancellationToken cancellationToken = default);
}

public interface IPasswordResetNotifier
{
    string ProviderName { get; }
    Task SendCodeAsync(User user, string destination, string code, CancellationToken cancellationToken = default);
}

public interface IOpenAiVisionService
{
    /// <summary>
    /// Reads product name/brand from packaging when visible; otherwise returns
    /// category noun guesses (same as legacy image search).
    /// </summary>
    Task<ImageProductVisionResult> SuggestProductNamesFromImageAsync(
        Stream imageStream,
        string fileName,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Asks OpenAI whether a product search query is misspelled and returns a corrected name when yes.
    /// </summary>
    Task<ProductSearchSpellCheckResult> CheckProductSearchSpellingAsync(
        string query,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Translates port English names to Arabic. Keys are port ids; values are Arabic names.
    /// </summary>
    Task<IReadOnlyDictionary<int, string>> TranslatePortNamesToArabicAsync(
        IReadOnlyList<PortNameTranslationItem> ports,
        CancellationToken cancellationToken = default);

    Task<(string TitleEn, string BodyEn, string TitleAr, string BodyAr)> EnsureBilingualNotificationAsync(
        string title, string body, CancellationToken cancellationToken = default);

    Task<(string NameEn, string NameAr)> EnsureBilingualStatusNameAsync(
        string statusName, CancellationToken cancellationToken = default);
}

public sealed class PortNameTranslationItem
{
    public int Id { get; init; }
    public string NameEn { get; init; } = string.Empty;
    public string? UnLocode { get; init; }
}

public interface IPortNameArBackfillService
{
    /// <summary>
    /// Fills Ports.PortNameAr for rows still null using OpenAI (batched).
    /// </summary>
    Task<PortNameArBackfillResult> BackfillAsync(
        int batchSize = 40,
        int maxBatches = 5,
        CancellationToken cancellationToken = default);
}

public sealed class PortNameArBackfillResult
{
    public int RemainingBefore { get; init; }
    public int Updated { get; init; }
    public int BatchesRun { get; init; }
    public int RemainingAfter { get; init; }
    public string? Message { get; init; }
}

public sealed class ProductFieldTranslations
{
    public string? NameAr { get; init; }
    public string? NameEn { get; init; }
    public string? DescriptionAr { get; init; }
    public string? DescriptionEn { get; init; }
    public string? RetailDescriptionAr { get; init; }
    public string? RetailDescriptionEn { get; init; }
    public string? SupplierNotesAr { get; init; }
    public string? SupplierNotesEn { get; init; }
    public string? ShippingDescriptionAr { get; init; }
    public string? ShippingDescriptionEn { get; init; }
}

public interface IContentTranslationService
{
    Task UpsertProductFieldsAsync(
        Guid productId,
        string? name,
        string? description,
        string? retailDescription,
        string? supplierNotes = null,
        string? shippingDescription = null,
        CancellationToken cancellationToken = default);

    Task UpsertOrderOfferNotesAsync(
        long orderId,
        string? notes,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyDictionary<Guid, ProductFieldTranslations>> GetProductTranslationsAsync(
        IEnumerable<Guid> productIds,
        CancellationToken cancellationToken = default);
}

public interface IMissedProductSearchAppService
{
    Task<object> GetPagedAsync(
        int page,
        int pageSize,
        string? search,
        DateTime? fromUtc,
        DateTime? toUtc,
        CancellationToken cancellationToken = default);
}

public interface IInternalDomesticShippingAppService
{
    Task<object> GetAllRatesAsync(CancellationToken cancellationToken = default);
    Task<object> GetPriceByEmirateAsync(string emirateName, CancellationToken cancellationToken = default);
    Task<object> UpdateRatesAsync(UpdateInternalDomesticShippingInput input, CancellationToken cancellationToken = default);
}

public interface IUserPreferencesAppService
{
    Task<object> GetPreferredLanguageAsync(string userId, CancellationToken cancellationToken = default);
    Task<object> UpdatePreferredLanguageAsync(string userId, UpdatePreferredLanguageInput input, CancellationToken cancellationToken = default);
}
