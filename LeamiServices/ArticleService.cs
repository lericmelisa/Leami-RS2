using Leami.Model.Entities;
using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services
{
    public class ArticleService : 
        BaseCRUDService<ArticleResponse,ArticleSearchObject,Article,ArticleInsertRequest,ArticleInsertRequest>,IArticleService
    {
        private readonly LeamiDbContext _context;   

        public ArticleService(LeamiDbContext context,IMapper mapper):base(context, mapper)
        {
            _context=context;
        }
        
        protected override IQueryable<Article> ApplyFilter(IQueryable<Article> query, ArticleSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.ArticleName))
            {
                query = query.Where(pt => pt.ArticleName.Contains(search.ArticleName));
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(pt => pt.ArticleName.Contains(search.FTS) || pt.ArticleCode.Contains(search.FTS));
            }
            return query;
        }

   

        //public async Task<List<ArticleResponse>> GetArticles(ArticleSearchObject? searchTerm)
        //{

        //    var queryable=_context.Articles.AsQueryable();
        //    if (!string.IsNullOrWhiteSpace(searchTerm?.ArticleName))
        //    {
        //       queryable=queryable.Where(x => x.ArticleName ==searchTerm.ArticleName);  
        //    }

        //    if (!string.IsNullOrWhiteSpace(searchTerm?.ArticleNameGTE))
        //    {
        //        queryable = queryable.Where(x => x.ArticleName.StartsWith(searchTerm.ArticleNameGTE));
        //    }

        //    if (!string.IsNullOrWhiteSpace(searchTerm?.FTS))
        //    {
        //        queryable = queryable.Where(x => x.ArticleName.Contains(searchTerm.FTS,StringComparison.CurrentCultureIgnoreCase) ||  (x.ArticleCode!=null && x.ArticleCode.Contains(searchTerm.FTS, StringComparison.CurrentCultureIgnoreCase)) );
        //    }


        //    var articles=await queryable.ToListAsync();

        //    return articles.Select(MapToResponse).ToList();

        //}


    }
}
