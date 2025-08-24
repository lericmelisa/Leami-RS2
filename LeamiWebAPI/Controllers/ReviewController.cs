using Leami.Model.Requests;
using Leami.Model.SearchObjects;
using Leami.Model.Responses;
using Leami.Services.Database;
using Mapster;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Leami.Services.IServices;
using Leami.Services.Database.Entities;
using Microsoft.EntityFrameworkCore;
using MapsterMapper;

namespace LeamiWebAPI.Controllers
{
    
    public class ReviewController : BaseCRUDController<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>    
    {
        public readonly IReviewService _reviewService;
        protected readonly LeamiDbContext _context;
        protected readonly IMapper _mapper;
        public ReviewController(IReviewService service,LeamiDbContext context,IMapper mapper):base(service)
        {
            _reviewService = service;
            _context = context;
            _mapper = mapper;   
        }

        [HttpPost]

        public override async Task<ReviewResponse> Create([FromBody] ReviewInsertRequest request)
        {
            // 1) Provjera: ima li korisnik narudžbu?
            //if (!await _orderService.UserHasAnyOrder(request.ReviewerUserId))
            //    throw new InvalidOperationException("Ne možete ostaviti recenziju dok nemate nijednu narudžbu.");

            // 2) Provjera: već postoji recenzija?
            var existing = await GetAsync(new ReviewSearchObject { ReviewerUserId = request.ReviewerUserId });
            if (existing.Any())
                throw new InvalidOperationException("Već ste ostavili recenziju. Ažurirajte postojeću.");

            // 3) Kreiraj entitet i postavi CreatedAt + ReviewerUser
            var entity = new Review();
            _mapper.Map(request, entity);
            entity.CreatedAt = DateTime.UtcNow;
            entity.ReviewerUser = await _context.Users.FindAsync(request.ReviewerUserId);

            _context.Reviews.Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<ReviewResponse>(entity);
        }
        
        [HttpPut("softDelete")]
        public async Task<ReviewResponse> SoftDeleteAsync([FromBody] ReviewSoftDeleteRequest dto)
        {
            var review = await _context.Reviews.FindAsync(dto.ReviewId);
          
            if (review == null) return null;

            review.IsDeleted = true;
            if(dto.DeletionReason!=null)
            review.DeletionReason = dto.DeletionReason;
            await _context.SaveChangesAsync();

            return _mapper.Map<ReviewResponse>(review);


        }

    }
}
