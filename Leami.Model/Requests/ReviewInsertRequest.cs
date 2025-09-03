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
        [Required(ErrorMessage = "Ne moze biti prazan ReviewerUserId.")]
        public int ReviewerUserId { get; set; }


        [Required(ErrorMessage = "Ne moze biti prazan Rating.")]
        [Range(1, 5, ErrorMessage = "Rating je u rangu od 1 do 5")]
        public short Rating { get; set; }

        [MaxLength(1000, ErrorMessage = "Komentar ne mooze imati vise od 1000 karaktera.")]
        public string? Comment { get; set; }
           
    }
}
