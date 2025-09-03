using Leami.Model.Entities;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.Database.Entities
{
    public class ReportExport
    {
        public int ReportExportId { get; set; }

        public int? UserId { get; set; }
        public User? User { get; set; }
        public DateTime From { get; set; }
        public DateTime To { get; set; }
        public int TotalUsers { get; set; }
        public int TotalOrders { get; set; }
        public decimal TotalRevenue { get; set; }
        [Required] public string TopArticlesJson { get; set; } = "[]";
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public int PdfSizeBytes { get; set; }
        public string? PdfSha256 { get; set; }
    }
}
