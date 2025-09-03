using Leami.Model.Requests;
using Leami.Model.SearchObjects;
using Leami.Services.Database;
using Leami.Services.Database.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Mapster;
using MapsterMapper;
using Leami.Services.IServices;
using Leami.Model.Responses;

namespace Leami.Services.Services
{
    public class OrderLService:BaseCRUDService<OrderResponse,BaseSearchObject,Order, OrderInsertRequest, OrderInsertRequest>,IOrderLService
    {
        private readonly LeamiDbContext _context;
        private readonly IMapper _mapper;   
        public OrderLService(LeamiDbContext leamiDb, IMapper mapper) : base(leamiDb, mapper)
        {
            _context = leamiDb;
            _mapper = mapper;
        }

        public override async Task<OrderResponse> CreateAsync(OrderInsertRequest req)
        {
         
            var order = new Order
            {
                UserId = req.UserId,
                OrderDate = DateTime.UtcNow,
                PaymentMethod = req.PaymentMethod,
                TotalAmount = req.TotalAmount,
            };

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();


            foreach (var itemRequest in req.Items)
            { 
                var orderItem = new OrderItem
                {
                    OrderId = order.OrderId,
                    ArticleId = itemRequest.ArticleId,
                    Quantity = itemRequest.Quantity,
                    UnitPrice = itemRequest.UnitPrice,
                   
                };
                _context.OrderItems.Add(orderItem);
                }

            await _context.SaveChangesAsync();

           
            // Mapiranje odgovora
            var response = new OrderResponse
            {
                OrderId = order.OrderId,
                UserId = order.UserId,
                OrderDate = order.OrderDate,
                TotalAmount = order.TotalAmount,
                PaymentMethod = order.PaymentMethod,
                Items = order.OrderItems.Where(i => i.OrderId == order.OrderId)
                    .Select(i => new OrderItemResponse
                    {
                        OrderItemId = i.OrderItemId,
                        ArticleId = i.ArticleId,
                        Quantity = i.Quantity,
                        UnitPrice = i.UnitPrice,
                        Total = i.Total
                    })
                    .ToList()
            };

            return response;
        }
            

         

           
    }
}
