using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class RestaurantInfoUpdateRequest
    {
        [Required] public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Address { get; set; }
        public string? Phone { get; set; }
        public byte[]? RestaurantImage { get; set; }
        public TimeSpan? OpeningTime { get; set; }

        [CustomValidation(typeof(RestaurantInfoUpdateRequest), nameof(ValidateClosingTime))]
        public TimeSpan? ClosingTime { get; set; }

        public static ValidationResult? ValidateClosingTime(TimeSpan? closing, ValidationContext ctx)
        {
            var instance = (RestaurantInfoUpdateRequest)ctx.ObjectInstance;
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
