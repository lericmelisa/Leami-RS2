using Leami.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services
{
    public interface ICRUDService<T,TSearch,TInsert,TUpdate>:IService<T, TSearch>
        where T : class
        where TSearch : BaseSearchObject
        where TInsert : class
        where TUpdate : class
    {
        Task<T> CreateAsync(TInsert request);
        Task<T> UpdateAsync(int id, TUpdate request);
        Task<bool> DeleteAsync(int id);
        
    }
}
