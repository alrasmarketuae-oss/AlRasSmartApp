namespace BusinessLayer.Dtos;

public sealed class AdminLiveCountsDto
{
    public int PendingUsers { get; set; }
    public int PendingProfileEdits { get; set; }
    public int PendingAds { get; set; }
    public int PendingAdEdits { get; set; }
    public int PendingOrders { get; set; }
    public int PendingOffers { get; set; }
    /// <summary>New Request ads awaiting first approval (for طلب / Reqs & Offers sidebar badge).</summary>
    public int PendingRequestOfferAds { get; set; }
    public int PendingShippingAds { get; set; }
    /// <summary>Pending Retail channel orders (type Retail / retail purchase).</summary>
    public int PendingRetailOrders { get; set; }
    /// <summary>Pending Booking orders.</summary>
    public int PendingBookingOrders { get; set; }
    /// <summary>Pending Offers (product type) orders.</summary>
    public int PendingOffersOrders { get; set; }
    /// <summary>Pending Categories / wholesale channel orders.</summary>
    public int PendingCategoriesOrders { get; set; }
    /// <summary>Pending AI/tech support callback requests.</summary>
    public int PendingSupportCallbacks { get; set; }
}

public sealed class AdminRealtimeAlertDto
{
    public string Type { get; set; } = string.Empty;
    public string? ReferenceId { get; set; }
    public string? DisplayName { get; set; }
    public string? SecondaryName { get; set; }
    public string? TertiaryName { get; set; }
    /// <summary>Formatted ordered quantity (e.g. "12").</summary>
    public string? Quantity { get; set; }
    /// <summary>Unit label for Quantity (e.g. "Kg").</summary>
    public string? UnitName { get; set; }
    /// <summary>Short order notes / product specs snippet for toast body.</summary>
    public string? Details { get; set; }
}
