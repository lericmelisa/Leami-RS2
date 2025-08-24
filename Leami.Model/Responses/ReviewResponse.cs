using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Responses
{
    public class ReviewResponse
    {
        public int ReviewId { get; set; }
        public int ReviewerUserId { get; set; }
        public short Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
        public UserResponse ReviewerUser { get; set; } = null!;
        public bool IsDeleted { get; set; } = false;

        public string? DeletionReason { get; set; } = string.Empty;


    }
}
