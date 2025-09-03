
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class ArticleInsertRequest
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "Article name ne moze biti prazan.")]
        [MinLength(2, ErrorMessage = "Article name ne moze biti manje od dva karaktera.")]
        [MaxLength(50, ErrorMessage = "Article name ne moze biti vise od 50 karaktera.")]
        public string ArticleName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Article price ne moze biti prazan.")]
        [Range(typeof(float), "1", "1000", ErrorMessage = "Article price je u rangu od 1 do 1000 KM")]
        public float ArticlePrice { get; set; }

        public string? ArticleDescription { get; set; }

        [Required(ErrorMessage = "Article category ne moze biti prazan.")]
        public int CategoryId { get; set; }


        [Required(ErrorMessage = "Article image nem oze biti prazan.")]
        public byte[] ArticleImage { get; set; }


    }
}
