using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Leami.Services.Database;
using Leami.Services.Database.Entities;

namespace Leami.Model.Entities
{
    public class Article
    {
       
        [Key]
        public int ArticleId { get; set; }
        public string ArticleName { get; set; } = string.Empty;
        public float ArticlePrice { get; set; }
        public string? ArticleDescription { get; set; }
        public byte[]? ArticleImage { get; set; }
        public int? CategoryId { get; set; }
        public Category? Category { get; set; } 

        //public List<ArticleOrder> ArticleOrder { get; set; } = new List<ArticleOrder>();    




    }
}
