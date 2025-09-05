using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class OrderItemInsertRequest
    {
        [Required(ErrorMessage = "ArticleId je obavezan.")]
        public int ArticleId { get; set; }

        [Required(ErrorMessage = "Količina je obavezna.")]
        [Range(1, 1000, ErrorMessage = "Količina mora biti između 1 i 1000.")]
        public int Quantity { get; set; }

        [Required(ErrorMessage = "Cijena po komadu je obavezna.")]
        [Range(0, 1000, ErrorMessage = "Cijena po komadu je u rasponu od 1 do 1000KM")]
        public decimal UnitPrice { get; set; }

       



    }
}
