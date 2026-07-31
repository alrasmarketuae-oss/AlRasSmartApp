using System.Data;
using System.Data.Common;
using Microsoft.Data.SqlClient;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace DataLayer.Repositories;

public sealed class ProductAdoRepository(
    IRasAlSouqDbContext dbContext,
    ILogger<ProductAdoRepository> logger)
{
    public sealed class DbPublicProductRow
    {
        public Guid ProductId { get; set; }
        public string? ProductCode { get; set; }
        public string? NameEn { get; set; }
        public decimal USDPrice { get; set; }
        public Guid? OwnerId { get; set; }
        public long Quantity { get; set; }
        public string? DescriptionEn { get; set; }
        public int? MinimumOrderQuantity { get; set; }
        public int? MaximumOrderQuantity { get; set; }
        public byte? Status { get; set; }
        public bool? IsApproved { get; set; }
        public byte? DiscountPercentage { get; set; }
        public short? DiscountDays { get; set; }
        public string? ShippingDescriptionEn { get; set; }
        public string? ShippingDuration { get; set; }
        public string? OfferDuration { get; set; }
        public string? SupplierNotesEn { get; set; }
        public byte? Packaging { get; set; }
        public string? PackagingDetails { get; set; }
        public byte? RetailPackaging { get; set; }
        public string? RetailPackagingDetails { get; set; }
        public string? RetailDescriptionEn { get; set; }
        public bool? Negotiable { get; set; }
        public bool IsFeatured { get; set; }
        public long ViewsCount { get; set; }
        public string? VideoPath { get; set; }
        public byte? VideoDurationSeconds { get; set; }
        public DateTime CreatedAt { get; set; }

        public string? CategoryName { get; set; }
        public string? CategoryNameAr { get; set; }
        public string? ProductTypeName { get; set; }
        public string? UnitName { get; set; }
        public string? OriginCountryName { get; set; }
        public string? OriginCountryNameAr { get; set; }
        public string? DestinationCountryName { get; set; }
        public string? DestinationCountryNameAr { get; set; }
        public string? LoadingPortName { get; set; }
        public string? LoadingPortNameAr { get; set; }
        public string? ArrivalPortName { get; set; }
        public string? ArrivalPortNameAr { get; set; }
        public byte? CategoryId { get; set; }
        public string Currency { get; set; } = "AED";
        public byte? ProductTypeId { get; set; }
        public Guid? AddressId { get; set; }

        public decimal? RetailPrice { get; set; }
        public byte? RetailUnitId { get; set; }
        public long? RetailQuantity { get; set; }
        public string? RetailUnitName { get; set; }

        public byte? RequestTypeId { get; set; }
        public string? RequestTypeName { get; set; }
        public byte? BookingPriceTypeId { get; set; }
        public string? BookingPriceTypeName { get; set; }
    }

    public async Task<string> InsertProductAsync(Product product, CancellationToken cancellationToken = default)
    {
        if (product is null) throw new ArgumentNullException(nameof(product));
        if (product.ProductId == Guid.Empty) throw new ArgumentException("ProductId is required.", nameof(product));
        if (product.OwnerId is null) throw new ArgumentException("OwnerId is required.", nameof(product));
        if (!product.UnitId.HasValue) throw new ArgumentException("UnitId is required.", nameof(product));

        var connection = ((DbContext)dbContext).Database.GetDbConnection();
        if (connection.State != ConnectionState.Open)
        {
            await connection.OpenAsync(cancellationToken);
        }

        await using var command = connection.CreateCommand();
        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_InsertProduct";

        AddParameter(command, "@ProductId", DbType.Guid, product.ProductId);
        AddParameter(command, "@OwnerId", DbType.Guid, product.OwnerId.Value);
        AddParameter(command, "@NameEn", DbType.String, product.NameEn);
        AddParameter(command, "@CreatedLanguage", DbType.String, product.CreatedLanguage);
        AddParameter(command, "@USDPrice", DbType.Decimal, product.USDPrice);
        AddParameter(command, "@Currency", DbType.String, product.Currency);
        AddParameter(command, "@Quantity", DbType.Int64, product.Quantity);
        AddParameter(command, "@DescriptionEn", DbType.String, product.DescriptionEn);
        AddParameter(command, "@CategoryId", DbType.Byte, product.CategoryId);
        AddParameter(command, "@ProductTypeId", DbType.Byte, product.ProductTypeId);
        AddParameter(command, "@UnitId", DbType.Byte, product.UnitId.Value);
        AddParameter(command, "@OriginCountryId", DbType.Int16, product.OriginCountryId);
        AddParameter(command, "@DestinationCountryId", DbType.Int16, product.DestinationCountryId);
        AddParameter(command, "@LoadingPortId", DbType.Int32, product.LoadingPortId);
        AddParameter(command, "@ArrivalPortId", DbType.Int32, product.ArrivalPortId);
        AddParameter(command, "@MinimumOrderQuantity", DbType.Int32, product.MinimumOrderQuantity);
        AddParameter(command, "@MaximumOrderQuantity", DbType.Int32, product.MaximumOrderQuantity);
        AddParameter(command, "@Status", DbType.Byte, product.Status);
        AddParameter(command, "@IsApproved", DbType.Boolean, product.IsApproved);
        AddParameter(command, "@IsReadyForAdminReview", DbType.Boolean, product.IsReadyForAdminReview);
        AddParameter(command, "@DiscountPercentage", DbType.Byte, product.DiscountPercentage);
        AddParameter(command, "@DiscountDays", DbType.Int16, product.DiscountDays);
        AddParameter(command, "@ShippingDescriptionEn", DbType.String, product.ShippingDescriptionEn);
        AddParameter(command, "@SupplierNotesEn", DbType.String, product.SupplierNotesEn);
        AddParameter(command, "@Packaging", DbType.Byte, product.Packaging);
        AddParameter(command, "@PackagingDetails", DbType.String, product.PackagingDetails);
        AddParameter(command, "@Negotiable", DbType.Boolean, product.Negotiable);
        AddParameter(command, "@VideoPath", DbType.String, product.VideoPath);
        AddParameter(command, "@VideoDurationSeconds", DbType.Byte, product.VideoDurationSeconds);
        AddParameter(command, "@ShippingDuration", DbType.String, product.ShippingDuration);
        AddParameter(command, "@OfferDuration", DbType.String, product.OfferDuration);
        AddParameter(command, "@AddressId", DbType.Guid, product.AddressId);
        AddParameter(command, "@RequestTypeId", DbType.Byte, product.RequestTypeId);
        AddParameter(command, "@BookingPriceTypeId", DbType.Byte, product.BookingPriceTypeId);
        AddParameter(command, "@RetailPrice", DbType.Decimal, product.RetailPrice);
        AddParameter(command, "@RetailUnitId", DbType.Byte, product.RetailUnitId);
        AddParameter(command, "@RetailQuantity", DbType.Int64, product.RetailQuantity);
        AddParameter(command, "@RetailPackaging", DbType.Byte, product.RetailPackaging);
        AddParameter(command, "@RetailPackagingDetails", DbType.String, product.RetailPackagingDetails);
        AddParameter(command, "@RetailDescriptionEn", DbType.String, product.RetailDescriptionEn);
        AddParameter(command, "@IsFeatured", DbType.Boolean, product.IsFeatured);
        AddParameter(command, "@ViewsCount", DbType.Int64, product.ViewsCount);
        AddParameter(command, "@CreatedAt", DbType.DateTime, product.CreatedAt);

        var productCodeParam = command.CreateParameter();
        productCodeParam.ParameterName = "@ProductCode";
        productCodeParam.DbType = DbType.String;
        productCodeParam.Direction = ParameterDirection.Output;
        productCodeParam.Size = 16;
        command.Parameters.Add(productCodeParam);

        try
        {
            // With SET NOCOUNT ON, ExecuteNonQuery often returns -1 even on success.
            // Success is determined by the OUTPUT ProductCode from usp_InsertProduct.
            await command.ExecuteNonQueryAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogError(
                ex,
                "usp_InsertProduct failed for product {ProductId} owner {OwnerId}",
                product.ProductId,
                product.OwnerId);
            throw;
        }

        var rawCode = productCodeParam.Value is null or DBNull
            ? null
            : Convert.ToString(productCodeParam.Value);
        if (string.IsNullOrWhiteSpace(rawCode))
        {
            logger.LogError(
                "usp_InsertProduct returned empty ProductCode for product {ProductId}",
                product.ProductId);
            throw new InvalidOperationException("Product could not be saved to the database.");
        }

        return rawCode;
    }

    public async Task<List<DbPublicProductRow>> GetProductsByIdsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default)
    {
        if (productIds is null) throw new ArgumentNullException(nameof(productIds));
        if (productIds.Count == 0) return [];

        var connection = ((DbContext)dbContext).Database.GetDbConnection();
        if (connection.State != ConnectionState.Open)
        {
            await connection.OpenAsync(cancellationToken);
        }

        var tvp = CreateProductIdTvp(productIds);

        await using var command = connection.CreateCommand();
        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = "dbo.usp_GetProductsByIds";

        var param = command.CreateParameter();
        param.ParameterName = "@ProductIds";
        param.Value = tvp;
        if (param is SqlParameter sqlParam)
        {
            sqlParam.SqlDbType = SqlDbType.Structured;
            sqlParam.TypeName = "dbo.ProductIdListType";
        }
        command.Parameters.Add(param);

        var result = new List<DbPublicProductRow>(productIds.Count);
        await using var reader = await command.ExecuteReaderAsync(CommandBehavior.SequentialAccess, cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            result.Add(ReadRow(reader));
        }

        return result;
    }

    private static DataTable CreateProductIdTvp(IReadOnlyList<Guid> productIds)
    {
        var table = new DataTable();
        table.Columns.Add("ProductId", typeof(Guid));
        foreach (var id in productIds)
        {
            table.Rows.Add(id);
        }

        return table;
    }

    private static DbPublicProductRow ReadRow(DbDataReader reader)
    {
        static string? GetNullableString(DbDataReader r, int ordinal)
            => r.IsDBNull(ordinal) ? null : r.GetString(ordinal);

        return new DbPublicProductRow
        {
            ProductId = reader.GetGuid(reader.GetOrdinal("ProductId")),
            ProductCode = GetNullableString(reader, reader.GetOrdinal("ProductCode")),
            NameEn = GetNullableString(reader, reader.GetOrdinal("NameEn")),
            USDPrice = reader.GetDecimal(reader.GetOrdinal("USDPrice")),
            OwnerId = reader.IsDBNull(reader.GetOrdinal("OwnerId")) ? null : reader.GetGuid(reader.GetOrdinal("OwnerId")),
            Quantity = reader.GetInt64(reader.GetOrdinal("Quantity")),
            DescriptionEn = GetNullableString(reader, reader.GetOrdinal("DescriptionEn")),
            MinimumOrderQuantity = reader.IsDBNull(reader.GetOrdinal("MinimumOrderQuantity")) ? null : reader.GetInt32(reader.GetOrdinal("MinimumOrderQuantity")),
            MaximumOrderQuantity = reader.IsDBNull(reader.GetOrdinal("MaximumOrderQuantity")) ? null : reader.GetInt32(reader.GetOrdinal("MaximumOrderQuantity")),
            Status = reader.IsDBNull(reader.GetOrdinal("Status")) ? null : (byte)reader.GetByte(reader.GetOrdinal("Status")),
            IsApproved = reader.IsDBNull(reader.GetOrdinal("IsApproved")) ? null : reader.GetBoolean(reader.GetOrdinal("IsApproved")),
            DiscountPercentage = reader.IsDBNull(reader.GetOrdinal("DiscountPercentage")) ? null : (byte)reader.GetByte(reader.GetOrdinal("DiscountPercentage")),
            DiscountDays = reader.IsDBNull(reader.GetOrdinal("DiscountDays")) ? null : (short)reader.GetInt16(reader.GetOrdinal("DiscountDays")),
            ShippingDescriptionEn = GetNullableString(reader, reader.GetOrdinal("ShippingDescriptionEn")),
            ShippingDuration = GetNullableString(reader, reader.GetOrdinal("ShippingDuration")),
            OfferDuration = GetNullableString(reader, reader.GetOrdinal("OfferDuration")),
            SupplierNotesEn = GetNullableString(reader, reader.GetOrdinal("SupplierNotesEn")),
            Packaging = reader.IsDBNull(reader.GetOrdinal("Packaging")) ? null : (byte)reader.GetByte(reader.GetOrdinal("Packaging")),
            PackagingDetails = GetNullableString(reader, reader.GetOrdinal("PackagingDetails")),
            RetailPackaging = reader.IsDBNull(reader.GetOrdinal("RetailPackaging")) ? null : (byte)reader.GetByte(reader.GetOrdinal("RetailPackaging")),
            RetailPackagingDetails = GetNullableString(reader, reader.GetOrdinal("RetailPackagingDetails")),
            RetailDescriptionEn = GetNullableString(reader, reader.GetOrdinal("RetailDescriptionEn")),
            Negotiable = reader.IsDBNull(reader.GetOrdinal("Negotiable")) ? null : reader.GetBoolean(reader.GetOrdinal("Negotiable")),
            IsFeatured = reader.GetBoolean(reader.GetOrdinal("IsFeatured")),
            ViewsCount = reader.GetInt64(reader.GetOrdinal("ViewsCount")),
            VideoPath = GetNullableString(reader, reader.GetOrdinal("VideoPath")),
            VideoDurationSeconds = reader.IsDBNull(reader.GetOrdinal("VideoDurationSeconds")) ? null : (byte)reader.GetByte(reader.GetOrdinal("VideoDurationSeconds")),
            CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt")),

            CategoryName = GetNullableString(reader, reader.GetOrdinal("CategoryName")),
            CategoryNameAr = GetNullableString(reader, reader.GetOrdinal("CategoryNameAr")),
            ProductTypeName = GetNullableString(reader, reader.GetOrdinal("ProductTypeName")),
            UnitName = GetNullableString(reader, reader.GetOrdinal("UnitName")),

            OriginCountryName = GetNullableString(reader, reader.GetOrdinal("OriginCountryName")),
            OriginCountryNameAr = GetNullableString(reader, reader.GetOrdinal("OriginCountryNameAr")),
            DestinationCountryName = GetNullableString(reader, reader.GetOrdinal("DestinationCountryName")),
            DestinationCountryNameAr = GetNullableString(reader, reader.GetOrdinal("DestinationCountryNameAr")),

            LoadingPortName = GetNullableString(reader, reader.GetOrdinal("LoadingPortName")),
            LoadingPortNameAr = GetNullableString(reader, reader.GetOrdinal("LoadingPortNameAr")),
            ArrivalPortName = GetNullableString(reader, reader.GetOrdinal("ArrivalPortName")),
            ArrivalPortNameAr = GetNullableString(reader, reader.GetOrdinal("ArrivalPortNameAr")),

            CategoryId = reader.IsDBNull(reader.GetOrdinal("CategoryId")) ? null : (byte)reader.GetByte(reader.GetOrdinal("CategoryId")),
            Currency = reader.IsDBNull(reader.GetOrdinal("Currency")) ? "AED" : reader.GetString(reader.GetOrdinal("Currency")),
            ProductTypeId = reader.IsDBNull(reader.GetOrdinal("ProductTypeId")) ? null : (byte)reader.GetByte(reader.GetOrdinal("ProductTypeId")),
            AddressId = reader.IsDBNull(reader.GetOrdinal("AddressId")) ? null : reader.GetGuid(reader.GetOrdinal("AddressId")),

            RetailPrice = reader.IsDBNull(reader.GetOrdinal("RetailPrice")) ? null : reader.GetDecimal(reader.GetOrdinal("RetailPrice")),
            RetailUnitId = reader.IsDBNull(reader.GetOrdinal("RetailUnitId")) ? null : (byte)reader.GetByte(reader.GetOrdinal("RetailUnitId")),
            RetailQuantity = reader.IsDBNull(reader.GetOrdinal("RetailQuantity")) ? null : reader.GetInt64(reader.GetOrdinal("RetailQuantity")),
            RetailUnitName = GetNullableString(reader, reader.GetOrdinal("RetailUnitName")),

            RequestTypeId = reader.IsDBNull(reader.GetOrdinal("RequestTypeId")) ? null : (byte)reader.GetByte(reader.GetOrdinal("RequestTypeId")),
            RequestTypeName = GetNullableString(reader, reader.GetOrdinal("RequestTypeName")),

            BookingPriceTypeId = reader.IsDBNull(reader.GetOrdinal("BookingPriceTypeId")) ? null : (byte)reader.GetByte(reader.GetOrdinal("BookingPriceTypeId")),
            BookingPriceTypeName = GetNullableString(reader, reader.GetOrdinal("BookingPriceTypeName")),
        };
    }

    private static void AddParameter(DbCommand command, string name, DbType type, object? value)
    {
        var p = command.CreateParameter();
        p.ParameterName = name;
        p.DbType = type;
        p.Value = value ?? DBNull.Value;
        command.Parameters.Add(p);
    }
}

