using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class MonthlyRevenueUpsertRequest
    {
        public DateTime Month { get; set; }
        public decimal TotalRevenue { get; set; }
    }
}
