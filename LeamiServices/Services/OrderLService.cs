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
using Leami.Model.Entities;
using Microsoft.EntityFrameworkCore;

namespace Leami.Services.Services
{
    public class OrderLService:BaseCRUDService<OrderResponse,OrderSearchObject,Order, OrderInsertRequest, OrderInsertRequest>,IOrderLService
    {
        private readonly LeamiDbContext _context;
        private readonly IMapper _mapper;   
        public OrderLService(LeamiDbContext leamiDb, IMapper mapper) : base(leamiDb, mapper)
        {
            _context = leamiDb;
            _mapper = mapper;
        }

        protected override IQueryable<Order> ApplyFilter(IQueryable<Order> query, OrderSearchObject search)
        {
            query = _context.Orders.Include(o => o.OrderItems).ThenInclude(oi => oi.Article);

            if (search.UserId.HasValue)
            {
                query = query.Where(a => a.UserId == search.UserId);
            }
            
          
            return query;
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


            foreach (var itemRequest in req.OrderItems)
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

            var response = new OrderResponse
            {
                OrderId = order.OrderId,
                UserId = order.UserId,
                OrderDate = order.OrderDate,
                TotalAmount = order.TotalAmount,
                PaymentMethod = order.PaymentMethod,
                OrderItems = order.OrderItems.Where(i => i.OrderId == order.OrderId)
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
