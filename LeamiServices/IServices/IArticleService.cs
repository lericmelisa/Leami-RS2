using Leami.Model.Entities;
using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.IServices
{
    public interface IArticleService : ICRUDService<ArticleResponse, ArticleSearchObject, ArticleInsertRequest, ArticleInsertRequest>
    {
        Task<List<ArticleResponse>> RecommendAsync(int articleId, int take = 3);
    }
}
