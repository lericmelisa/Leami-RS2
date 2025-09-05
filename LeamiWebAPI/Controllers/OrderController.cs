using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.IServices;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace LeamiWebAPI.Controllers
{

    public class OrderController : BaseCRUDController<OrderResponse, OrderSearchObject, OrderInsertRequest, OrderInsertRequest>
    {

        private readonly IOrderLService _service;
        public OrderController(IOrderLService orderService):base(orderService)
        {
            _service = orderService;
        }
   


    }
}
