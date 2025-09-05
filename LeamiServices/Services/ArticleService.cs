using Leami.Model.Entities;
using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.Database;
using Leami.Services.IServices;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.ML;
using Microsoft.ML.Data;

namespace Leami.Services.Services
{
    public class ArticleService :
        BaseCRUDService<ArticleResponse, ArticleSearchObject, Article, ArticleInsertRequest, ArticleInsertRequest>, IArticleService
    {
        private readonly LeamiDbContext _context;
        private static readonly object _lock = new();
        private static MLContext? _ml;
        private static ITransformer? _model;
        private static DataViewSchema? _modelSchema;
        private static DateTime _modelBuiltAt = DateTime.MinValue;

        public ArticleService(LeamiDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        protected override IQueryable<Article> ApplyFilter(IQueryable<Article> query, ArticleSearchObject search)
        {

            if (search.CategoryId.HasValue)
            {
                query = query.Where(a => a.CategoryId == search.CategoryId.Value);
            }
            if (!string.IsNullOrEmpty(search.ArticleName))
            {
                query = query.Where(pt => pt.ArticleName.Contains(search.ArticleName));
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(pt => pt.ArticleName.Contains(search.FTS));
            }
            return query;
        }
        public async Task<List<ArticleResponse>> RecommendAsync(int articleId, int take = 3)
        {
         
            var orders = await _context.Orders
                .Include(o => o.OrderItems)              
                .ToListAsync();

            var pairs = new List<CoPurchaseInput>();
            foreach (var o in orders)
            {
                var items = o.OrderItems                    
                              .Select(oi => oi.ArticleId)   
                              .Distinct()
                              .ToList();

                if (items.Count <= 1) continue;

                foreach (var a in items)
                {
                    foreach (var b in items)
                    {
                        if (a == b) continue;
                        pairs.Add(new CoPurchaseInput
                        {
                            ProductId = (uint)a,
                            CoProductId = (uint)b,
                            Label = 1f 
                        });
                    }
                }
            }

            if (pairs.Count == 0)
                return new List<ArticleResponse>();

            EnsureModel(pairs);

            if (_model is null || _ml is null)
                return new List<ArticleResponse>();

            // 2) Kandidati = sva ostala artikla
            var candidateArticles = await _context.Articles
                .Where(a => a.ArticleId != articleId)
                .ToListAsync();

            if (candidateArticles.Count == 0)
                return new List<ArticleResponse>();

       
            var inputs = candidateArticles.Select(c => new CoPurchaseInput
            {
                ProductId = (uint)articleId,
                CoProductId = (uint)c.ArticleId,
                Label = 0f // nije bitno za predikciju
            });

            var inputView = _ml.Data.LoadFromEnumerable(inputs);
            var scored = _model.Transform(inputView);

            var scores = _ml.Data.CreateEnumerable<CoPurchaseScore>(scored, reuseRowObject: false).ToList();

            // Zip kandidat + score
            var ranked = candidateArticles.Zip(scores, (art, sc) => new { art, sc.Score })
                                          .OrderByDescending(x => x.Score)
                                          .Take(Math.Max(1, take))
                                          .Select(x => x.art)
                                          .ToList();

            return ranked.Select(MapToResponse).ToList();
        }

        private void EnsureModel(List<CoPurchaseInput> pairs)
        {
            var needRebuild = (_model == null) || (DateTime.UtcNow - _modelBuiltAt > TimeSpan.FromMinutes(30));
            if (!needRebuild) return;

            lock (_lock)
            {
                // Reprovjeri unutar locka
                if (_model != null && (DateTime.UtcNow - _modelBuiltAt <= TimeSpan.FromMinutes(30)))
                    return;

                _ml ??= new MLContext(seed: 42);
                var data = _ml.Data.LoadFromEnumerable(pairs);

                var pipeline =
                    _ml.Transforms.Conversion.MapValueToKey("ProductIdEncoded", nameof(CoPurchaseInput.ProductId))
                      .Append(_ml.Transforms.Conversion.MapValueToKey("CoProductIdEncoded", nameof(CoPurchaseInput.CoProductId)))
                      .Append(_ml.Recommendation().Trainers.MatrixFactorization(new Microsoft.ML.Trainers.MatrixFactorizationTrainer.Options
                      {
                          MatrixColumnIndexColumnName = "ProductIdEncoded",
                          MatrixRowIndexColumnName = "CoProductIdEncoded",
                          LabelColumnName = nameof(CoPurchaseInput.Label),
                          LossFunction = Microsoft.ML.Trainers.MatrixFactorizationTrainer.LossFunctionType.SquareLossOneClass,
                          Alpha = 0.01,
                          Lambda = 0.025,
                          NumberOfIterations = 100,
                          C = 0.00001
                      }));

                _model = pipeline.Fit(data);
                _modelSchema = data.Schema;
                _modelBuiltAt = DateTime.UtcNow;
            }
        }


       

        // ===== helper DTO-i za ML =====
        private sealed class CoPurchaseInput
        {
          public uint ProductId { get; set; }
          public uint CoProductId { get; set; }
          public float Label { get; set; }
        }

        private sealed class CoPurchaseScore
        {
            public float Score { get; set; }
        }
    




    }
}
