using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class MonthlyCountUpsertRequest
    {
        public DateTime Month { get; set; }
        public int TotalCount { get; set; }
    }
}
