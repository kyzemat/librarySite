using System.ComponentModel.DataAnnotations;

namespace WebApplication1.Models
{
    public class book
    {
        [Key]
        public int book_id { get; set; }
        public string name { get; set; }
        public string path_to_book_cover { get; set; }
        public DateTime year_of_production { get; set; }
        public int number_of_pages { get; set; }
        public decimal cost_per_day { get; set; }
        public int available_copies { get; set; }
        public string isbn { get; set; }
        public string description { get; set; }
    }
}
