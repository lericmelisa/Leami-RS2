using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public partial class ReservationInsertRequest : IValidatableObject
    {
        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            // 1) Datum+vrijeme u budućnosti (realni trenutak, ne samo dan)
            var reservationDateTime = ReservationDate.ToDateTime(ReservationTime);
            if (reservationDateTime < DateTime.Now)
            {
                yield return new ValidationResult(
                    "Datum i vrijeme rezervacije ne smiju biti u prošlosti.",
                    new[] { nameof(ReservationDate), nameof(ReservationTime) });
            }

          
        }

        [Required(ErrorMessage = "Datum rezervacije je obavezan.")]
      
        public DateOnly ReservationDate { get; set; }

        [Required(ErrorMessage = "Vrijeme rezervacije je obavezno.")]
      
        public TimeOnly ReservationTime { get; set; }

        [Required(ErrorMessage = "Broj gostiju je obavezan.")]
        [Range(1, 100, ErrorMessage = "Broj gostiju može biti između 1 i 100.")]
        public int NumberOfGuests { get; set; }

        [Required(ErrorMessage = "Status mora biti validan broj.")]
        public int ReservationStatus { get; set; }

        [Required(ErrorMessage = "UserId je obavezan.")]
        public int UserId { get; set; }

        [MaxLength(1000, ErrorMessage = "Razlog može imati najviše 1000 karaktera.")]
        public string? ReservationReason { get; set; }

        [Range(0, 100, ErrorMessage = "Broj maloljetnika može biti između 0 i 100.")]
        public int? NumberOfMinors { get; set; }

        [Required(AllowEmptyStrings = false, ErrorMessage = "Kontakt telefon je obavezan.")]
        [Phone(ErrorMessage = "Telefon nije u validnom formatu.")]
        public string ContactPhone { get; set; } = null!;

        [MaxLength(2000, ErrorMessage = "Posebni zahtjevi mogu imati najviše 100 karaktera.")]
        public string? SpeciaLRequests { get; set; }
    }
}
