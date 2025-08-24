using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class ReviewInsertRequest
    {
        [Required(ErrorMessage = "This field can not be empty.")]
        public int ReviewerUserId { get; set; }
        [Required(ErrorMessage = "This field can not be empty.")]
        [Range(1, 5, ErrorMessage = "The rating number can be in a range from 1 to 5")]
        public short Rating { get; set; }
        [MaxLength(1000, ErrorMessage = "The comment can't have more than 1000 characters.")]
        public string? Comment { get; set; }
           
    }
}
