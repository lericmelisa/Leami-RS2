using Leami.Services.IServices;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("[controller]")]
public class ReportsController : ControllerBase
{
    private readonly IReportService _svc;
    public ReportsController(IReportService svc) => _svc = svc;

    [HttpGet("stats")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetStats(
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to)
    {
        if (from.HasValue && to.HasValue)
        {
            return Ok(new
            {
                totalUsers = await _svc.GetTotalUsersAsyncDate(from.Value, to.Value),
                totalOrders = await _svc.GetTotalOrdersAsyncDate(from.Value, to.Value),
                totalRevenue = await _svc.GetTotalRevenueAsyncDate(from.Value, to.Value),
            });
        }
        // fallback: cijeli skup
        return Ok(new
        {
            totalUsers = await _svc.GetTotalUsersAsync(),
            totalOrders = await _svc.GetTotalOrdersAsync(),
            totalRevenue = await _svc.GetTotalRevenueAsync(),
        });
    }

    [HttpGet("top-articles")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> TopArticles() =>
        Ok(await _svc.GetTopArticlesAsync());

    [HttpGet("revenue-by-month")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> RevenueByMonth(
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to)
    {
        if (from.HasValue && to.HasValue)
            return Ok(await _svc.GetRevenueByMonthAsyncDate(from.Value, to.Value));

        return Ok(await _svc.GetRevenueByMonthAsync());
    }

        [HttpGet("download")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DownloadReport(
        [FromQuery] DateTime from,
        [FromQuery] DateTime to)
    {
        var pdf = await _svc.GeneratePdfReportAsync(from, to);
        return File(pdf, "application/pdf", $"Report_{DateTime.Now:yyyyMMdd}.pdf");
    }

    [HttpGet("orders-by-month")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> OrdersByMonth([FromQuery] DateTime? from,
        [FromQuery] DateTime? to)
    {
        if (from.HasValue && to.HasValue)
            return Ok(await _svc.GetOrdersByMonthAsyncDate(from.Value, to.Value));

        // ako nema intervala, možeš i dalje fallback-ati na zadnjih 6 mjeseci
        return Ok(await _svc.GetOrdersByMonthAsync());
    }


}
