using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class RestaurantInfoInsertRequest
    {
    
            [Required(ErrorMessage = "Naziv restorana je obavezan.")]
            [MinLength(2, ErrorMessage = "Naziv ne smije biti kraći od 2 znaka.")]
            [StringLength(50, ErrorMessage = "Naziv ne smije biti duži od 50 znakova.")]
            public string Name { get; set; } = string.Empty;

            [StringLength(1000, ErrorMessage = "Opis ne smije biti dulji od 100 znakova.")]
            public string? Description { get; set; }

            [Required(ErrorMessage = "Adresa restorana je obavezna.")]
            [StringLength(100, ErrorMessage = "Adresa ne smije biti dulja od 100 znakova.")]
            public string? Address { get; set; }

            [Required(ErrorMessage = "Telefon restorana je obavezan.")]
            [Phone(ErrorMessage = "Neispravan format telefona.")]
            [StringLength(50, ErrorMessage = "Telefon ne smije biti dulji od 50 znakova.")]
            public string Phone { get; set; }

            public byte[]? RestaurantImage { get; set; }

            [Required(ErrorMessage = "Vrijeme otvaranja je obavezno.")]
            public TimeSpan? OpeningTime { get; set; }

        [Required(ErrorMessage = "Vrijeme zatvaranja je obavezno.")]
        [CustomValidation(typeof(RestaurantInfoInsertRequest), nameof(ValidateClosingTime))]
        public TimeSpan? ClosingTime { get; set; }

        public static ValidationResult? ValidateClosingTime(TimeSpan? closing, ValidationContext ctx)
        {
            var instance = (RestaurantInfoInsertRequest)ctx.ObjectInstance;
            if (instance.OpeningTime == null || closing == null)
                return ValidationResult.Success;

            if (closing <= instance.OpeningTime)
                return new ValidationResult(
                    "Vrijeme zatvaranja mora biti nakon vremena otvaranja.",
                    new[] { nameof(ClosingTime) }
                );

            return ValidationResult.Success;
        }
    }
    }

