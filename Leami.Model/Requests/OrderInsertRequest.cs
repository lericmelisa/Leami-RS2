using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class OrderInsertRequest
    {
        [Required(ErrorMessage = "Korisnik je obavezan.")]
        public int UserId { get; set; }

        [Required(ErrorMessage = "Datum narudžbe je obavezan.")]
        public DateTime OrderDate { get; set; }

        [Required(ErrorMessage = "Ukupna cijena je obavezan.")]
        public decimal TotalAmount { get; set; }


        [MaxLength(50, ErrorMessage = "Način plaćanja može sadržavati najviše 50 karaktera.")]
        public string? PaymentMethod { get; set; } // Cash, Card...

        [Required(ErrorMessage = "Stavke narudžbe su obavezne.")]
        [MinLength(1, ErrorMessage = "Potrebna je najmanje jedna stavka.")]
        public List<OrderItemInsertRequest> Items { get; set; } = new();


    }
}
