using Leami.Model.Responses;
using Leami.Model.SearchObjects;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services
{
    public interface IService<T,TSearch> where T : class where TSearch : BaseSearchObject 
    {
        Task<PagedResult<T>> GetAsync(TSearch search);
        Task<T?> GetByIdAsync(int id);
    }
}
