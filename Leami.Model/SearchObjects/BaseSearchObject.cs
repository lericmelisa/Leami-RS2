using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.SearchObjects
{
    public class BaseSearchObject
    {
        public string? FTS { get; set; }
        public int? Page { get; set; } = 0;
        public int? PageSize { get; set; } = 10;
        public bool IncludeTotalCount { get; set; } = false;

        public bool RetrieveAll { get; set; } = false;

    }
}
