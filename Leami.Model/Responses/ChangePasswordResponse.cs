using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Model.Responses
{
    public class ChangePasswordResponse
    {
        public string? Token { get; set; }
        public DateTime? Expiration { get; set; }
    }
}
