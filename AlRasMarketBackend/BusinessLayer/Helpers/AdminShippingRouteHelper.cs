using BusinessLayer.Interfaces;
using DataLayer.Models;

namespace BusinessLayer.Helpers;

public static class AdminShippingRouteHelper
{
    public sealed record RouteNames(
        short FromCountryId,
        int FromPortId,
        short ToCountryId,
        int ToPortId,
        string FromCountryName,
        string? FromCountryNameAr,
        string FromPortName,
        string? FromPortUnLocode,
        string ToCountryName,
        string? ToCountryNameAr,
        string ToPortName,
        string? ToPortUnLocode)
    {
        public string RouteSummaryEn =>
            FormatRoute(FromCountryName, FromPortName, ToCountryName, ToPortName);

        public string RouteSummaryAr =>
            FormatRoute(
                FromCountryNameAr ?? FromCountryName,
                FromPortName,
                ToCountryNameAr ?? ToCountryName,
                ToPortName);
    }

    public static RouteNames Resolve(InternationalShippingPost post, IStaticReferenceCache cache)
    {
        var fromCountryCache = cache.FindCountryById(post.FromCountryId);
        var toCountryCache = cache.FindCountryById(post.ToCountryId);
        var fromPortCache = cache.FindPortById(post.FromPortId);
        var toPortCache = cache.FindPortById(post.ToPortId);

        var fromCountryName = FirstNonEmpty(
            post.FromCountry?.CountryNameEn,
            fromCountryCache?.CountryNameEn);
        var toCountryName = FirstNonEmpty(
            post.ToCountry?.CountryNameEn,
            toCountryCache?.CountryNameEn);
        var fromPortName = FirstNonEmpty(
            post.FromPort?.PortNameEn,
            fromPortCache?.PortNameEn);
        var toPortName = FirstNonEmpty(
            post.ToPort?.PortNameEn,
            toPortCache?.PortNameEn);

        return new RouteNames(
            post.FromCountryId,
            post.FromPortId,
            post.ToCountryId,
            post.ToPortId,
            fromCountryName,
            FirstNonEmpty(post.FromCountry?.CountryNameAr, fromCountryCache?.CountryNameAr),
            fromPortName,
            FirstNonEmpty(post.FromPort?.UnLocode, fromPortCache?.UnLocode),
            toCountryName,
            FirstNonEmpty(post.ToCountry?.CountryNameAr, toCountryCache?.CountryNameAr),
            toPortName,
            FirstNonEmpty(post.ToPort?.UnLocode, toPortCache?.UnLocode));
    }

    private static string FormatRoute(
        string fromCountry,
        string fromPort,
        string toCountry,
        string toPort)
    {
        var from = JoinLocation(fromCountry, fromPort);
        var to = JoinLocation(toCountry, toPort);

        if (string.IsNullOrWhiteSpace(from) && string.IsNullOrWhiteSpace(to))
        {
            return string.Empty;
        }

        if (string.IsNullOrWhiteSpace(from))
        {
            return to;
        }

        if (string.IsNullOrWhiteSpace(to))
        {
            return from;
        }

        return $"{from} → {to}";
    }

    private static string JoinLocation(string country, string port)
    {
        if (string.IsNullOrWhiteSpace(country) && string.IsNullOrWhiteSpace(port))
        {
            return string.Empty;
        }

        if (string.IsNullOrWhiteSpace(port))
        {
            return country;
        }

        if (string.IsNullOrWhiteSpace(country))
        {
            return port;
        }

        return $"{country} · {port}";
    }

    private static string FirstNonEmpty(params string?[] values)
    {
        foreach (var value in values)
        {
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value.Trim();
            }
        }

        return string.Empty;
    }
}
