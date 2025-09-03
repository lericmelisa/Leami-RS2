using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text.Json;
using System.Threading.Tasks;
using Leami.Model.Requests;
using Leami.Services.Database;         // tvoj DbContext
using Leami.Services.Database.Entities;
using Leami.Services.IServices;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;                  // za PDF
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

public class ReportService : IReportService
{
    private readonly LeamiDbContext _db;
    private readonly IHttpContextAccessor _http;
    public ReportService(LeamiDbContext db, IHttpContextAccessor http)
    {
        _db = db;
        _http = http;

    }


    public async Task<int> GetTotalUsersAsync()
        => await _db.Users.CountAsync();

    public async Task<int> GetTotalOrdersAsync()
        => await _db.Orders.CountAsync();

    public async Task<decimal> GetTotalRevenueAsync()
        => await _db.Orders.SumAsync(o => o.TotalAmount);

    public async Task<List<ArticleSalesUpsertRequest>> GetTopArticlesAsync(int topN = 5)
    {
        return await _db.OrderItems
            .Include(oi => oi.Article)
            .GroupBy(oi => new { oi.ArticleId, oi.Article.ArticleName })
            .Select(g => new ArticleSalesUpsertRequest
            {
                ArticleId = g.Key.ArticleId,
                ArticleName = g.Key.ArticleName,
                QuantitySold = g.Sum(x => x.Quantity),
                Revenue = g.Sum(x => x.Quantity * x.UnitPrice)
            })
            .OrderByDescending(x => x.QuantitySold)
            .Take(topN)
            .ToListAsync();
    }
    public async Task<List<MonthlyCountUpsertRequest>> GetOrdersByMonthAsync(int monthsBack = 6)
    {
        var cutoff = DateTime.UtcNow.AddMonths(-monthsBack);
        var raw = await _db.Orders
          .Where(o => o.OrderDate >= cutoff)
          .GroupBy(o => new { o.OrderDate.Year, o.OrderDate.Month })
          .Select(g => new {
              g.Key.Year,
              g.Key.Month,
              Count = g.Count()
          })
          .ToListAsync();

        return raw
          .OrderBy(x => x.Year).ThenBy(x => x.Month)
          .Select(x => new MonthlyCountUpsertRequest
          {
              Month = new DateTime(x.Year, x.Month, 1),
              TotalCount = x.Count
          })
          .ToList();
    }

    public async Task<List<MonthlyRevenueUpsertRequest>> GetRevenueByMonthAsync(int monthsBack = 6)
    {
        var cutoff = DateTime.UtcNow.AddMonths(-monthsBack);

        // 1) SQL-preview: samo Year, Month i suma
        var raw = await _db.Orders
            .Where(o => o.OrderDate >= cutoff)
            .GroupBy(o => new { o.OrderDate.Year, o.OrderDate.Month })
            .Select(g => new
            {
                Year = g.Key.Year,
                Month = g.Key.Month,
                Total = g.Sum(o => o.TotalAmount)
            })
            .ToListAsync();

        // 2) Klijent: kreiraj DTO sa stvarnim DateTime-om
        return raw
            .OrderBy(x => x.Year).ThenBy(x => x.Month)
            .Select(x => new MonthlyRevenueUpsertRequest
            {
                Month = new DateTime(x.Year, x.Month, 1),
                TotalRevenue = x.Total
            })
            .ToList();
    }
    public async Task<List<MonthlyCountUpsertRequest>> GetOrdersByMonthAsyncDate(DateTime from, DateTime to)
    {
        var raw = await _db.Orders
         .Where(o => o.OrderDate >= from && o.OrderDate <= to)
         .GroupBy(o => new { o.OrderDate.Year, o.OrderDate.Month })
         .Select(g => new {
             Year = g.Key.Year,
             Month = g.Key.Month,
             Count = g.Count()
         })
         .ToListAsync();

        // 2) Generiraj listu svih mjeseci u intervalu
        var monthList = new List<DateTime>();
        var current = new DateTime(from.Year, from.Month, 1);
        var end = new DateTime(to.Year, to.Month, 1);
        while (current <= end)
        {
            monthList.Add(current);
            current = current.AddMonths(1);
        }

        // 3) Napravi lookup iz raw rezultata
        var lookup = raw.ToDictionary(
            x => new DateTime(x.Year, x.Month, 1),
            x => x.Count
        );

        // 4) Sastavi finalnu listu s default 0 gdje nema podataka
        var result = monthList
            .Select(dt => new MonthlyCountUpsertRequest
            {
                Month = dt,
                TotalCount = lookup.TryGetValue(dt, out var cnt) ? cnt : 0
            })
            .ToList();

        return result;
    }

    public async Task<List<MonthlyRevenueUpsertRequest>> GetRevenueByMonthAsyncDate(DateTime from, DateTime to)
    {
        // 1. Pokupi sve postojeće podatke iz baze
        var raw = await _db.Orders
            .Where(o => o.OrderDate >= from && o.OrderDate <= to)
            .GroupBy(o => new { o.OrderDate.Year, o.OrderDate.Month })
            .Select(g => new {
                Year = g.Key.Year,
                Month = g.Key.Month,
                Total = g.Sum(o => o.TotalAmount)
            })
            .ToListAsync();

        // 2. Generiraj popis svih mjeseci u rasponu
        var monthList = new List<DateTime>();
        var current = new DateTime(from.Year, from.Month, 1);
        var end = new DateTime(to.Year, to.Month, 1);
        while (current <= end)
        {
            monthList.Add(current);
            current = current.AddMonths(1);
        }

        // 3. Mapiraj raw rezultate u dictionary za brzi lookup
        var lookup = raw.ToDictionary(
            x => new DateTime(x.Year, x.Month, 1),
            x => x.Total
        );

        // 4. Sastavi finalnu listu, postavljajući 0 za nepostojeće mjesece
        var result = monthList
            .Select(dt => new MonthlyRevenueUpsertRequest
            {
                Month = dt,
                TotalRevenue = lookup.TryGetValue(dt, out var total) ? total : 0m
            })
            .ToList();

        return result;
    }

    public async Task<int> GetTotalUsersAsyncDate(DateTime from, DateTime to)
    {
        // broj jedinstvenih korisnika koji su imali narudžbu u periodu
        return await _db.Orders
            .Where(o => o.OrderDate >= from && o.OrderDate <= to)
            .Select(o => o.UserId)
            .Distinct()
            .CountAsync();
    }

    public async Task<int> GetTotalOrdersAsyncDate(DateTime from, DateTime to)
    {
        return await _db.Orders
            .Where(o => o.OrderDate >= from && o.OrderDate <= to)
            .CountAsync();
    }

    public async Task<decimal> GetTotalRevenueAsyncDate(DateTime from, DateTime to)
    {
        return await _db.Orders
            .Where(o => o.OrderDate >= from && o.OrderDate <= to)
            .SumAsync(o => o.TotalAmount);
    }

    public async Task<List<ArticleSalesUpsertRequest>> GetTopArticlesAsyncDate(DateTime from, DateTime to, int topN = 5)
    {
        // grupiraj samo po artiklima iz OrderItems čija je narudžba u periodu
        return await _db.OrderItems
            .Include(oi => oi.Article)
            .Where(oi => oi.Order.OrderDate >= from && oi.Order.OrderDate <= to)
            .GroupBy(oi => new { oi.ArticleId, oi.Article.ArticleName })
            .Select(g => new ArticleSalesUpsertRequest
            {
                ArticleId = g.Key.ArticleId,
                ArticleName = g.Key.ArticleName,
                QuantitySold = g.Sum(x => x.Quantity),
                Revenue = g.Sum(x => x.Quantity * x.UnitPrice)
            })
            .OrderByDescending(x => x.QuantitySold)
            .Take(topN)
            .ToListAsync();
    }
    static readonly JsonSerializerOptions _jsonOpts = new()
    {
        PropertyNamingPolicy = null,
        WriteIndented = false
    };


    private int? GetCurrentUserIdOrNull()
    {
        var uidStr = _http.HttpContext?.User?.FindFirstValue("uid");
        return int.TryParse(uidStr, out var id) ? id : (int?)null;
    }
    public async Task<byte[]> GeneratePdfReportAsync(DateTime from, DateTime to)
    {
        var principal = _http.HttpContext?.User;

        var claimsDebug = principal?.Claims
            ?.Select(c => $"{c.Type} = {c.Value}")
            ?.ToList();

        Console.WriteLine("CLAIMS >>>");
        if (claimsDebug != null)
            foreach (var c in claimsDebug) Console.WriteLine(c);
        else
            Console.WriteLine("NEMA CLAIMOVA (nije autentificiran?)");

        var totalUsers = await GetTotalUsersAsyncDate(from, to);
        var totalOrders = await GetTotalOrdersAsyncDate(from, to);
        var totalRevenue = await GetTotalRevenueAsyncDate(from, to);
        var topArticles = await GetTopArticlesAsyncDate(from, to);
        var monthlyRev = await GetRevenueByMonthAsyncDate(from, to);
        var monthlyOrders = await GetOrdersByMonthAsyncDate(from, to);

        var document = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Margin(40);

                // Header
                page.Header()
                    .Text("📊 Leami poslovni izvještaj")
                    .FontSize(22)
                    .SemiBold()
                    .FontColor(Colors.Blue.Medium)
                    .AlignCenter();

                // Content
                page.Content().Column(col =>
                {
                    col.Spacing(10);

                    // Period
                    col.Item()
                       .Text($"📅 Period: {from:dd.MM.yyyy} – {to:dd.MM.yyyy}")
                       .FontSize(12)
                       .FontColor(Colors.Grey.Darken2);

                    // Divider
                    col.Item()
                       .LineHorizontal(1)
                       .LineColor(Colors.Grey.Lighten2);

                    // Summary cards
                    col.Item().Row(row =>
                    {
                        void Card(Action<IContainer> build) =>
                            row.RelativeItem()
                               .Padding(8)
                               .Background(Colors.Grey.Lighten4)
                               .MinHeight(50)
                               .Element(build);

                        Card(c => c.Text($"👥 Gosti: {totalUsers}")
                                  .FontSize(12).SemiBold());
                        Card(c => c.Text($"🛒 Narudžbe: {totalOrders}")
                                  .FontSize(12).SemiBold());
                        Card(c => c.Text($"💰 Profit: {totalRevenue:C}")
                                  .FontSize(12).SemiBold());
                    });

                    // Top articles
                    col.Item()
                       .Text("✨ Top 5 artikala")
                       .FontSize(14)
                       .Bold();

                    col.Item().Table(table =>
                    {
                        table.ColumnsDefinition(cd =>
                        {
                            cd.RelativeColumn(3);
                            cd.RelativeColumn();
                            cd.RelativeColumn();
                        });

                        table.Header(header =>
                        {
                            header.Cell().Background(Colors.Blue.Medium).Padding(5)
                                  .Text("Artikal").FontColor(Colors.White);
                            header.Cell().Background(Colors.Blue.Medium).Padding(5)
                                  .AlignRight().Text("Količina").FontColor(Colors.White);
                            header.Cell().Background(Colors.Blue.Medium).Padding(5)
                                  .AlignRight().Text("Profit").FontColor(Colors.White);
                        });

                        foreach (var a in topArticles)
                        {
                            table.Cell().Padding(5).Text(a.ArticleName);
                            table.Cell().Padding(5).AlignRight().Text(a.QuantitySold.ToString());
                            table.Cell().Padding(5).AlignRight().Text(a.Revenue.ToString("F2"));
                        }
                    });

                    // Page break before monthly tables
                    col.Item().PageBreak();

                    // Orders by month
                    col.Item()
                       .Text("📊 Narudžbe po mjesecima")
                       .FontSize(14)
                       .Bold();

                    col.Item().Table(table =>
                    {
                        table.ColumnsDefinition(cd =>
                        {
                            cd.RelativeColumn(2);
                            cd.RelativeColumn();
                        });

                        table.Header(header =>
                        {
                            header.Cell().Background(Colors.Green.Medium).Padding(5)
                                  .Text("Mjesec").FontColor(Colors.White);
                            header.Cell().Background(Colors.Green.Medium).Padding(5)
                                  .AlignRight().Text("Narudžbi").FontColor(Colors.White);
                        });

                        foreach (var o in monthlyOrders)
                        {
                            table.Cell().Padding(5).Text(o.Month.ToString("yyyy-MM"));
                            table.Cell().Padding(5).AlignRight().Text(o.TotalCount.ToString());
                        }
                    });

                    // Monthly revenue
                    col.Item()
                       .Text("📈 Prihod po mjesecima")
                       .FontSize(14)
                       .Bold();

                    col.Item().Table(table =>
                    {
                        table.ColumnsDefinition(cd =>
                        {
                            cd.RelativeColumn(2);
                            cd.RelativeColumn();
                        });

                        table.Header(header =>
                        {
                            header.Cell().Background(Colors.Purple.Medium).Padding(5)
                                  .Text("Mjesec").FontColor(Colors.White);
                            header.Cell().Background(Colors.Purple.Medium).Padding(5)
                                  .AlignRight().Text("Prihod").FontColor(Colors.White);
                        });

                        foreach (var m in monthlyRev)
                        {
                            table.Cell().Padding(5).Text(m.Month.ToString("yyyy-MM"));
                            table.Cell().Padding(5).AlignRight().Text(m.TotalRevenue.ToString("F2"));
                        }
                    });
                });

                // Footer
                page.Footer().AlignCenter().Text(text =>
                {
                    text.CurrentPageNumber(); text.Span("/"); text.TotalPages()
                        .FontSize(10)
                        .FontColor(Colors.Grey.Darken1);
                });
            });
        });

        var userId = GetCurrentUserIdOrNull();

        var topArticlesJson = JsonSerializer.Serialize(topArticles, _jsonOpts);


        var export = new ReportExport
        {
            UserId = userId,
            From = from.Date,
            To = to.Date,
            TotalUsers = totalUsers,
            TotalOrders = totalOrders,
            TotalRevenue = totalRevenue,
            TopArticlesJson = topArticlesJson,
            CreatedAt = DateTime.UtcNow
        };

        _db.ReportExports.Add(export);
        await _db.SaveChangesAsync();

        return document.GeneratePdf();
    }


}
