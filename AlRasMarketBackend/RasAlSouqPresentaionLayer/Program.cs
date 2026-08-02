using System.Text;
using System.Text.Json;
using System.Reflection;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Cors.Infrastructure;
using Microsoft.AspNetCore.HttpLogging;
using Microsoft.AspNetCore.StaticFiles;
using BusinessLayer.Constants;
using RasAlSouqPresentaionLayer.Authorization;
using RasAlSouqPresentaionLayer.Middleware;
using RasAlSouqPresentaionLayer.Hubs;
using BusinessLayer.Factories;
using BusinessLayer.Interfaces;
using BusinessLayer.LoginServices;
using BusinessLayer.PasswordHelper;
using BusinessLayer.Services;
using BusinessLayer.Services.AiAssistant;
using BusinessLayer.Services.AiAssistant.Mcp;
using BusinessLayer.Services.ImageSearch;
using BusinessLayer.TokenService;
using BusinessLayer.Caching;
using BusinessLayer.Options;
using BusinessLayer.Services.Storage;
using RasAlSouqPresentaionLayer.Services;
using DataLayer.Interfaces;
using DataLayer.Models;
using DataLayer.Repositories;
using DataLayer.Seeding;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Microsoft.AspNetCore.ResponseCompression;
using Prometheus;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.RateLimiting;
using StackExchange.Redis;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("DefaultConnection is not configured.");
var connectionInfo = new Microsoft.Data.SqlClient.SqlConnectionStringBuilder(connectionString);

builder.Services.AddDbContext<IRasAlSouqDbContext, RasAlSouqDbContext>(options =>
{
    options.UseSqlServer(connectionString);
});

builder.Services.AddHttpContextAccessor();
builder.Services.Configure<CloudflareR2Options>(builder.Configuration.GetSection(CloudflareR2Options.SectionName));
builder.Services.AddSingleton<IMediaUrlResolver, MediaUrlResolver>();
builder.Services.AddSingleton<LocalWebRootFileStorage>();
builder.Services.AddSingleton<IFileStorage>(sp =>
{
    var r2 = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<CloudflareR2Options>>().Value;
    var local = sp.GetRequiredService<LocalWebRootFileStorage>();
    if (!r2.IsConfigured)
    {
        return local;
    }

    var r2Storage = ActivatorUtilities.CreateInstance<CloudflareR2FileStorage>(sp);
    var logger = sp.GetRequiredService<Microsoft.Extensions.Logging.ILogger<CompositeFileStorage>>();
    return new CompositeFileStorage(r2Storage, local, logger);
});
builder.Services.AddScoped<IMediaStorageService, MediaStorageService>();
builder.Services.AddScoped<IUserLanguageResolver, UserLanguageResolver>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IPasswordHasher, PasswordHasher>();
builder.Services.AddScoped<ITokenService, BusinessLayer.TokenService.TokenService>();
builder.Services.AddScoped<LoginProviderFactory>();
builder.Services.AddScoped<PasswordResetNotifierFactory>();
builder.Services.AddScoped<ILoginService, LoginService>();
builder.Services.AddSingleton<IFcmNotificationService, FcmNotificationService>();
builder.Services.AddSingleton<IEmailService, EmailService>();
builder.Services.AddHttpClient<ISmsService, SmsService>();
builder.Services.AddScoped<IEmailOtpService, EmailOtpService>();
builder.Services.Configure<CloudflareTurnstileOptions>(
    builder.Configuration.GetSection(CloudflareTurnstileOptions.SectionName));
builder.Services.AddHttpClient(nameof(TurnstileVerifier));
builder.Services.AddScoped<ITurnstileVerifier, TurnstileVerifier>();
builder.Services.AddScoped<IAuthAppService, AuthAppService>();
builder.Services.AddScoped<IAccountDeletionAppService, AccountDeletionAppService>();
builder.Services.AddScoped<IAdminCompaniesAppService, AdminCompaniesAppService>();
builder.Services.AddScoped<IAdminGlobalSearchAppService, AdminGlobalSearchAppService>();
builder.Services.AddScoped<IAdminDashboardAppService, AdminDashboardAppService>();
builder.Services.AddScoped<IAdminPermissionService, AdminPermissionService>();
builder.Services.AddScoped<IAdminEmployeesAppService, AdminEmployeesAppService>();
builder.Services.AddScoped<IAdminAuditLogAppService, AdminAuditLogAppService>();
builder.Services.AddScoped<IMissedProductSearchAppService, MissedProductSearchAppService>();
builder.Services.AddScoped<IAdminUsersAppService, AdminUsersAppService>();
builder.Services.AddScoped<IAdminOrdersAppService, AdminOrdersAppService>();
builder.Services.AddScoped<IAdminShippingAppService, AdminShippingAppService>();
builder.Services.AddScoped<IAdminRealtimeNotificationService, RasAlSouqPresentaionLayer.Services.AdminRealtimeNotificationService>();
builder.Services.AddScoped<IOrderRealtimeNotificationService, RasAlSouqPresentaionLayer.Services.OrderRealtimeNotificationService>();
builder.Services.AddScoped<IAdminNotificationsAppService, AdminNotificationsAppService>();
builder.Services.AddSingleton<IAdminPushNotificationQueue, AdminPushNotificationQueue>();
builder.Services.AddHostedService<AdminPushNotificationWorker>();
builder.Services.AddHostedService<BusinessLayer.Services.DraftMediaCleanupWorker>();
builder.Services.AddScoped<IProductImageVectorIndexingProcessor, ProductImageVectorIndexingProcessor>();
builder.Services.AddScoped<IAdminProductsAppService, AdminProductsAppService>();
builder.Services.AddScoped<IAdminSettingsAppService, AdminSettingsAppService>();
builder.Services.AddScoped<IInternalDomesticShippingAppService, InternalDomesticShippingAppService>();
builder.Services.AddScoped<IUserPreferencesAppService, UserPreferencesAppService>();
builder.Services.AddSingleton<ICommissionSettingsProvider, CommissionSettingsProvider>();
builder.Services.AddSingleton<ICategoryCommissionProvider, CategoryCommissionProvider>();
builder.Services.AddSingleton<IInternalDomesticShippingProvider, InternalDomesticShippingProvider>();
builder.Services.AddSingleton<StaticReferenceCache>();
builder.Services.AddSingleton<IStaticReferenceCache>(sp => sp.GetRequiredService<StaticReferenceCache>());
builder.Services.AddSingleton<IGeoReferenceCache>(sp => sp.GetRequiredService<StaticReferenceCache>());
builder.Services.AddScoped<ICompanyImagesAppService, CompanyImagesAppService>();
builder.Services.AddScoped<ICompanyLicenceAppService, CompanyLicenceAppService>();
builder.Services.AddScoped<INotificationsAppService, NotificationsAppService>();
builder.Services.AddScoped<IProductAssetsAppService, ProductAssetsAppService>();
builder.Services.AddScoped<ProductAdoRepository>();
builder.Services.AddScoped<IProductDataAccess, ProductDataAccess>();
builder.Services.AddScoped<IOrderDataAccess, OrderDataAccess>();
builder.Services.AddScoped<IBalanceDataAccess, BalanceDataAccess>();
builder.Services.AddScoped<ISupplierBalanceService, SupplierBalanceService>();
builder.Services.AddScoped<IUserIbanAppService, UserIbanAppService>();
builder.Services.AddScoped<IWithdrawalRequestsAppService, WithdrawalRequestsAppService>();
builder.Services.AddScoped<IAdminFinanceAppService, AdminFinanceAppService>();
builder.Services.AddScoped<IProductsAppService, ProductsAppService>();
builder.Services.AddHttpClient<IOpenAiVisionService, OpenAiVisionService>(client =>
{
    client.Timeout = TimeSpan.FromSeconds(45);
});
builder.Services.Configure<QdrantOptions>(builder.Configuration.GetSection(QdrantOptions.SectionName));
builder.Services.Configure<ImageEmbeddingOptions>(builder.Configuration.GetSection(ImageEmbeddingOptions.SectionName));
builder.Services.Configure<MeilisearchOptions>(builder.Configuration.GetSection(MeilisearchOptions.SectionName));
builder.Services.Configure<AiAssistantOptions>(
    builder.Configuration.GetSection(AiAssistantOptions.SectionName));
builder.Services.AddSingleton<IConfigurationAccessor, ConfigurationAccessor>();
builder.Services.AddHttpClient<IImageEmbeddingService, ClipHttpEmbeddingService>(client =>
{
    // Indexing jobs use their own CTS; search caps wait separately (~12s).
    client.Timeout = TimeSpan.FromSeconds(45);
});
builder.Services.AddHttpClient<IProductImageVectorIndex, QdrantProductImageVectorIndex>((sp, client) =>
{
    var qdrant = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<QdrantOptions>>().Value;
    client.BaseAddress = new Uri((qdrant.Url ?? "http://localhost:6333").TrimEnd('/') + "/");
    client.Timeout = TimeSpan.FromSeconds(30);
});
builder.Services.AddHttpClient<IAiKnowledgeIndex, QdrantAiKnowledgeIndex>((sp, client) =>
{
    var ai = sp.GetRequiredService<
        Microsoft.Extensions.Options.IOptions<AiAssistantOptions>>().Value;
    client.BaseAddress = new Uri((ai.QdrantUrl ?? "http://localhost:6333").TrimEnd('/') + "/");
    client.Timeout = TimeSpan.FromSeconds(30);
});
builder.Services.AddHttpClient<IAiTextEmbeddingService, OpenAiTextEmbeddingService>(client =>
{
    client.Timeout = TimeSpan.FromSeconds(30);
});
builder.Services.AddScoped<IAiAssistantToolsService, AiAssistantMcpToolsService>();
builder.Services.AddScoped<IAiAssistantMcpToolLoop, AiAssistantMcpToolLoop>();
builder.Services.AddHttpClient<IAiAssistantAppService, AiAssistantAppService>(client =>
{
    client.Timeout = TimeSpan.FromSeconds(90);
});
builder.Services.AddHostedService<AiKnowledgeBootstrapHostedService>();
builder.Services.AddHttpClient<IProductTextSearchIndex, MeilisearchProductTextSearchIndex>((sp, client) =>
{
    var meili = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<MeilisearchOptions>>().Value;
    client.BaseAddress = new Uri((meili.Url ?? "http://localhost:7700").TrimEnd('/') + "/");
    client.Timeout = TimeSpan.FromSeconds(20);
});
builder.Services.AddScoped<ProductTextSearchSyncService>();
builder.Services.AddHostedService<ProductTextSearchBootstrapHostedService>();
builder.Services.AddHttpClient(nameof(ContentTranslationService));
builder.Services.AddScoped<IContentTranslationService, ContentTranslationService>();
builder.Services.AddScoped<IPortNameArBackfillService, PortNameArBackfillService>();
builder.Services.AddScoped<IAddressesAppService, AddressesAppService>();
builder.Services.AddScoped<ICategoriesAppService, CategoriesAppService>();
builder.Services.AddScoped<IOffersAppService, OffersAppService>();
builder.Services.AddScoped<IInternationalShippingAppService, InternationalShippingAppService>();
builder.Services.AddScoped<IShippingCompanyAppService, ShippingCompanyAppService>();
builder.Services.AddScoped<ICartAppService, CartAppService>();
builder.Services.AddScoped<IOrdersAppService, OrdersAppService>();
builder.Services.AddScoped<IPaymentsAppService, PaymentsAppService>();
builder.Services.AddScoped<IHomeBannersAppService, HomeBannersAppService>();
builder.Services.AddScoped<IProfileAppService, ProfileAppService>();
builder.Services.AddScoped<RasAlSouqPresentaionLayer.Filters.ActiveUserAuthorizationFilter>();
builder.Services.AddScoped<RasAlSouqPresentaionLayer.Filters.LocalizeApiMessagesFilter>();
builder.Services.AddScoped<IChatAppService, ChatAppService>();
builder.Services.AddSignalR();
builder.Services.AddMemoryCache();
builder.Services.Configure<RedisOptions>(builder.Configuration.GetSection(RedisOptions.SectionName));

var redisConfig = builder.Configuration.GetSection(RedisOptions.SectionName).Get<RedisOptions>()
    ?? new RedisOptions();
IConnectionMultiplexer? redisMultiplexer = null;
if (redisConfig.Enabled && !string.IsNullOrWhiteSpace(redisConfig.ConnectionString))
{
    try
    {
        redisMultiplexer = ConnectionMultiplexer.Connect(redisConfig.ConnectionString);
        builder.Services.AddSingleton<IConnectionMultiplexer>(redisMultiplexer);
        Console.WriteLine($"Redis connected ({redisConfig.ConnectionString}).");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Redis unavailable — product cache uses memory only. ({ex.Message})");
    }
}

var useRedisStreams = redisMultiplexer is not null;
if (useRedisStreams)
{
    // Durable event bus: Create Ad XADDs translation/CLIP work; workers XREADGROUP + XACK.
    builder.Services.AddSingleton<IProductTranslationQueue, RedisStreamProductTranslationQueue>();
    builder.Services.AddSingleton<IProductBackgroundEventQueue, DirectProductBackgroundEventQueue>();
    builder.Services.AddSingleton<IProductImageIndexingQueue, RedisStreamProductImageIndexingQueue>();
    Console.WriteLine("Product background queues: Redis Streams (translate + CLIP).");
}
else
{
    builder.Services.AddSingleton<IProductBackgroundEventQueue, ProductBackgroundEventQueue>();
    builder.Services.AddSingleton<IProductTranslationQueue, ProductTranslationQueue>();
    builder.Services.AddSingleton<IProductImageIndexingQueue, ProductImageIndexingQueue>();
    builder.Services.AddHostedService<ProductCreatedEventWorker>();
    Console.WriteLine("Product background queues: in-process Channels (Redis Streams unavailable).");
}

builder.Services.AddHostedService<ProductTranslationWorker>();
builder.Services.AddHostedService<ProductImageIndexingWorker>();

builder.Services.AddSingleton<ProductCacheVersions>(sp =>
    new ProductCacheVersions(
        sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<RedisOptions>>(),
        sp.GetRequiredService<Microsoft.Extensions.Logging.ILogger<ProductCacheVersions>>(),
        sp.GetService<IConnectionMultiplexer>()));
builder.Services.AddSingleton<ITieredCache>(sp =>
    new TieredCache(
        sp.GetRequiredService<Microsoft.Extensions.Caching.Memory.IMemoryCache>(),
        sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<RedisOptions>>(),
        sp.GetRequiredService<Microsoft.Extensions.Logging.ILogger<TieredCache>>(),
        sp.GetService<IConnectionMultiplexer>()));
builder.Services.AddHttpClient();
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy("ai-assistant", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            context.User.FindFirst("EntityId")?.Value
                ?? context.Connection.RemoteIpAddress?.ToString()
                ?? "anonymous",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 12,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
                AutoReplenishment = true
            }));
});

var jwt = builder.Configuration.GetSection("JwtSettings");
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwt["Issuer"],
        ValidAudience = jwt["Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"] ?? throw new InvalidOperationException("JWT key is missing")))
    };

    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var path = context.HttpContext.Request.Path;
            if (!path.StartsWithSegments("/chathub")
                && !path.StartsWithSegments("/adminhub")
                && !path.StartsWithSegments("/aihub"))
            {
                return Task.CompletedTask;
            }

            var accessToken = context.Request.Query["access_token"].ToString();
            if (string.IsNullOrWhiteSpace(accessToken))
            {
                var authHeader = context.Request.Headers.Authorization.ToString();
                if (authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
                {
                    accessToken = authHeader["Bearer ".Length..].Trim();
                }
            }

            if (!string.IsNullOrWhiteSpace(accessToken))
            {
                context.Token = accessToken;
            }

            return Task.CompletedTask;
        }
    };
});

builder.Services.AddSingleton<IAuthorizationHandler, AdminPermissionAuthorizationHandler>();
builder.Services.AddAuthorization(options =>
{
    foreach (var permission in AdminPermissions.AllKeys)
    {
        options.AddPolicy(
            $"AdminPermission:{permission}",
            policy => policy.Requirements.Add(new AdminPermissionRequirement(permission)));
    }
});
var corsExtraHosts = builder.Configuration.GetSection("Cors:ExtraAllowedHosts").Get<string[]>() ?? [];
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAdminDashboard", policy =>
    {
        policy
            .SetIsOriginAllowed(origin =>
            {
                if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri))
                {
                    return false;
                }

                if (uri.Host is "localhost" or "127.0.0.1" or "192.168.70.169")
                {
                    return true;
                }

                if (uri.Host.StartsWith("192.168.", StringComparison.Ordinal))
                {
                    return true;
                }

                if (uri.Host.Equals("gomango01-001-site1.mtempurl.com", StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }

                if (uri.Host.EndsWith(".mtempurl.com", StringComparison.OrdinalIgnoreCase)
                    || uri.Host.EndsWith(".ltempurl.com", StringComparison.OrdinalIgnoreCase)
                    || uri.Host.EndsWith(".jtempurl.com", StringComparison.OrdinalIgnoreCase)
                    || uri.Host.EndsWith(".qtempurl.com", StringComparison.OrdinalIgnoreCase)
                    || uri.Host.EndsWith(".tempurl.host", StringComparison.OrdinalIgnoreCase)
                    || uri.Host.EndsWith(".netlify.app", StringComparison.OrdinalIgnoreCase)
                    || uri.Host.EndsWith(".alrasmarketapp.com", StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }

                return corsExtraHosts.Any(host =>
                    uri.Host.Equals(host, StringComparison.OrdinalIgnoreCase)
                    || uri.Host.EndsWith($".{host}", StringComparison.OrdinalIgnoreCase));
            })
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});
builder.Logging.AddConsole();
builder.Logging.AddDebug();

if (builder.Environment.IsDevelopment())
{
    builder.Services.AddHttpLogging(logging =>
    {
        logging.LoggingFields =
            HttpLoggingFields.RequestMethod
            | HttpLoggingFields.RequestPath
            | HttpLoggingFields.RequestQuery
            | HttpLoggingFields.ResponseStatusCode
            | HttpLoggingFields.Duration;
        logging.CombineLogs = true;
    });
}
builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
});

builder.Services.Configure<BrotliCompressionProviderOptions>(options =>
{
    options.Level = System.IO.Compression.CompressionLevel.Fastest;
});

builder.Services.Configure<GzipCompressionProviderOptions>(options =>
{
    options.Level = System.IO.Compression.CompressionLevel.Fastest;
});
builder.Services.AddControllers(options =>
{
    options.Filters.Add<RasAlSouqPresentaionLayer.Filters.ActiveUserAuthorizationFilter>();
    options.Filters.Add<RasAlSouqPresentaionLayer.Filters.LocalizeApiMessagesFilter>();
})
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.PropertyNameCaseInsensitive = true;
    });
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "RasAlSouq API", Version = "v1" });
    var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        options.IncludeXmlComments(xmlPath, includeControllerXmlComments: true);
    }

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Type: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders =
        ForwardedHeaders.XForwardedFor |
        ForwardedHeaders.XForwardedProto
});
app.Logger.LogInformation(
    "API started env={Environment} db={DataSource}/{InitialCatalog}",
    app.Environment.EnvironmentName,
    connectionInfo.DataSource,
    connectionInfo.InitialCatalog);

Stripe.StripeConfiguration.ApiKey = builder.Configuration["Stripe:SecretKey"];

await using (var scope = app.Services.CreateAsyncScope())
{
    var db = scope.ServiceProvider.GetRequiredService<IRasAlSouqDbContext>();
    // Schema columns (e.g. Categories.IsHide) must exist before any EF category queries.
    await CategoryProductSchemaMigrator.EnsureAsync(db);
    // Must run before any EF Products query (e.g. ProductCodeSchemaMigrator).
    // RetailCode is mapped on Product; add the column before EF selects Products rows.
    await ProductReadyForAdminReviewSchemaMigrator.EnsureAsync(db);
    await PendingProductChangesSchemaMigrator.EnsureAsync(db);
    await ProductRetailPricingSchemaMigrator.EnsureAsync(db);
    await ProductRetailChannelDetailsSchemaMigrator.EnsureAsync(db);
    await ProductRetailCodeSchemaMigrator.EnsureAsync(db);
    await ProductCodeSchemaMigrator.EnsureAsync(db);
    await ProductStoredProceduresSchemaMigrator.EnsureAsync(db);
    await OrderSchemaMigrator.EnsureAsync(db);
    await CartSchemaMigrator.EnsureAsync(db);
    await UserSchemaMigrator.EnsureAsync(db);
    await RoleSchemaMigrator.EnsureAsync(db);
    await InternationalShippingPostSchemaMigrator.EnsureAsync(db);
    await SystemSettingsSchemaMigrator.EnsureAsync(db);
    await AdminPushNotificationSchemaMigrator.EnsureAsync(db);
    await QueryPerformanceIndexMigrator.EnsureAsync(db);
    await ShippingSchemaMigrator.EnsureAsync(db);
    await InternalDomesticShippingSchemaMigrator.EnsureAsync(db);
    await ChatSchemaMigrator.EnsureAsync(db);
    await OfferSchemaMigrator.EnsureAsync(db);
    await ProductOfferDurationSchemaMigrator.EnsureAsync(db);
    await ProductCreatedLanguageSchemaMigrator.EnsureAsync(db);
    await ProductVideoSchemaMigrator.EnsureAsync(db);
    await RequestTypeSchemaMigrator.EnsureAsync(db);
    await BookingPriceTypeSchemaMigrator.EnsureAsync(db);
    await AdminEmployeeSchemaMigrator.EnsureAsync(db);
    await AdminAuditLogSchemaMigrator.EnsureAsync(db);
    await MissedProductSearchSchemaMigrator.EnsureAsync(db);
    await ContentTranslationSchemaMigrator.EnsureAsync(db);
    await ProductUnicodeColumnsMigrator.EnsureAsync(db);
    await PortNameArSchemaMigrator.EnsureAsync(db);
    await NotificationSchemaMigrator.EnsureAsync(db);
    await NotificationBilingualSchemaMigrator.EnsureAsync(db);
    await BalanceSchemaMigrator.EnsureAsync(db);
    await UserIbanSchemaMigrator.EnsureAsync(db);
    await WithdrawalRequestSchemaMigrator.EnsureAsync(db);
    CategoriesListCache.Bump();
    ProductsAppService.InvalidateProductListCaches();

    var staticReferenceCache = scope.ServiceProvider.GetRequiredService<IStaticReferenceCache>();
    await staticReferenceCache.EnsureLoadedAsync();

    var internalDomesticShippingProvider = scope.ServiceProvider.GetRequiredService<IInternalDomesticShippingProvider>();
    await internalDomesticShippingProvider.EnsureLoadedAsync();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();
// Request/info logging only in Development — production logs errors only (see appsettings).
if (app.Environment.IsDevelopment())
{
    app.UseHttpLogging();
    app.UseMiddleware<RequestLoggingMiddleware>();
}
app.UseResponseCompression();
app.UseHttpMetrics();
app.UseCors("AllowAdminDashboard");

var staticContentTypes = new FileExtensionContentTypeProvider();
staticContentTypes.Mappings[".m4a"] = "audio/mp4";
staticContentTypes.Mappings[".aac"] = "audio/aac";
staticContentTypes.Mappings[".weba"] = "audio/webm";
staticContentTypes.Mappings[".caf"] = "audio/x-caf";
staticContentTypes.Mappings[".3gp"] = "audio/3gpp";
staticContentTypes.Mappings[".3gpp"] = "audio/3gpp";
staticContentTypes.Mappings[".amr"] = "audio/amr";
// Static files (product-images, videos, documents) short-circuit the pipeline.
// Apply the same CORS policy so dash.alrasmarketapp.com can canvas/fetch assets.
app.UseStaticFiles(new StaticFileOptions
{
    ContentTypeProvider = staticContentTypes,
    OnPrepareResponse = ctx =>
    {
        // Cache for 1 year
        ctx.Context.Response.Headers.Append(
            "Cache-Control",
            "public,max-age=31536000,immutable");

        //  Video Streaming
        ctx.Context.Response.Headers.Append(
            "Accept-Ranges",
            "bytes");

        var httpContext = ctx.Context;

        if (string.IsNullOrWhiteSpace(httpContext.Request.Headers.Origin))
        {
            return;
        }

        var corsService = httpContext.RequestServices.GetRequiredService<ICorsService>();
        var corsPolicyProvider = httpContext.RequestServices.GetRequiredService<ICorsPolicyProvider>();

        var policy = corsPolicyProvider
            .GetPolicyAsync(httpContext, "AllowAdminDashboard")
            .GetAwaiter()
            .GetResult();

        if (policy is null)
        {
            return;
        }

        var corsResult = corsService.EvaluatePolicy(httpContext, policy);
        corsService.ApplyResult(corsResult, httpContext.Response);
    },
});
app.UseAuthentication();
app.UseRateLimiter();
app.UseMiddleware<UserLanguageMiddleware>();
app.UseAuthorization();
app.MapControllers();
app.MapHub<ChatHub>("/chathub").RequireCors("AllowAdminDashboard");
app.MapHub<AiAssistantHub>("/aihub").RequireCors("AllowAdminDashboard");
app.MapHub<AdminNotificationHub>("/adminhub").RequireCors("AllowAdminDashboard");
app.MapHub<OrderHub>("/orderhub").RequireCors("AllowAdminDashboard");

app.MapGet("/api/health", async (IRasAlSouqDbContext db, CancellationToken cancellationToken) =>
{
    if (db is not DbContext context)
    {
        return Results.Problem("Database context is not available.");
    }

    var canConnect = await context.Database.CanConnectAsync(cancellationToken);
    var productCount = canConnect
        ? await context.Set<Product>().CountAsync(cancellationToken)
        : (int?)null;

    return Results.Ok(new
    {
        status = canConnect ? "ok" : "db_unreachable",
        utc = DateTime.UtcNow,
        environment = app.Environment.EnvironmentName,
        database = new
        {
            dataSource = connectionInfo.DataSource,
            catalog = connectionInfo.InitialCatalog,
            canConnect,
            productCount
        }
    });
});

// Internal scrape target for Prometheus (not published via nginx).
app.MapMetrics();

app.Run();
