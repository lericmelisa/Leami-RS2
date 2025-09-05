using Leami.Model.Entities;
using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.Database;
using Leami.Services.Database.Entities;
using Leami.Services.IServices;
using MapsterMapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.Services
{
    public class ReviewLService : BaseCRUDService<ReviewResponse, ReviewSearchObject, Review, ReviewInsertRequest, ReviewUpdateRequest>, IReviewService
    {
        protected readonly LeamiDbContext _context;
        protected readonly IMapper mapper;
        public ReviewLService(LeamiDbContext dbContext, IMapper _mapper) : base(dbContext, _mapper)
        {
            _context = dbContext;
            mapper = _mapper;    

        }

        protected override IQueryable<Review> ApplyFilter(IQueryable<Review> query, ReviewSearchObject search)
        {
            

            query = query.Include(r => r.ReviewerUser)
                .Where(r => !r.IsDeleted);

            if (search.ReviewerUserId.HasValue)
                query = query.Where(r => r.ReviewerUserId == search.ReviewerUserId.Value);

            if (!string.IsNullOrWhiteSpace(search.FTS))
            {
                var term = search.FTS.Trim();
                query = query.Where(x =>
                    x.ReviewerUser!.FirstName.Contains(term) ||
                    x.ReviewerUser.LastName.Contains(term) ||
                    x.CreatedAt.ToString().Contains(term)
                );
            }

            return query;
        } 





    }
}

