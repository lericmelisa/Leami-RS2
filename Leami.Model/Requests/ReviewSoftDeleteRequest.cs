using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class ReviewSoftDeleteRequest
    {
        public int ReviewId { get; set; }
        public bool IsDeleted { get; set; } = false;
        public string? DeletionReason { get; set; } = string.Empty;
    }
}
