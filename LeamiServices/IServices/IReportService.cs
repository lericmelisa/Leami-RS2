using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Leami.Model.Requests;
namespace Leami.Services.IServices
{
    public interface IReportService
    {
        Task<int> GetTotalUsersAsync();
        Task<int> GetTotalOrdersAsync();
        Task<decimal> GetTotalRevenueAsync();
        Task<List<ArticleSalesUpsertRequest>> GetTopArticlesAsync(int topN = 5);
        Task<List<MonthlyRevenueUpsertRequest>> GetRevenueByMonthAsync(int monthsBack = 6);
        Task<byte[]> GeneratePdfReportAsync(DateTime from, DateTime to);
        Task<List<MonthlyCountUpsertRequest>> GetOrdersByMonthAsync(int monthsBack = 6);



        Task<int> GetTotalUsersAsyncDate(DateTime from, DateTime to);
        Task<int> GetTotalOrdersAsyncDate(DateTime from, DateTime to);
        Task<decimal> GetTotalRevenueAsyncDate(DateTime from, DateTime to);
        Task<List<ArticleSalesUpsertRequest>> GetTopArticlesAsyncDate(DateTime from, DateTime to, int topN = 5);

        Task<List<MonthlyCountUpsertRequest>> GetOrdersByMonthAsyncDate(DateTime from, DateTime to);
        Task<List<MonthlyRevenueUpsertRequest>> GetRevenueByMonthAsyncDate(DateTime from, DateTime to);
    }
}
