using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Requests
{
    public class ReviewUpdateRequest
    {
        public short? Rating { get; set; }
        public string? Comment { get; set; }
       

    }
}
