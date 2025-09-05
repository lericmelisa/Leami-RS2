using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;

namespace Leami.Services.IServices
{
    public interface IOrderLService:ICRUDService<OrderResponse, OrderSearchObject, OrderInsertRequest, OrderInsertRequest>    
    {
    }
}
