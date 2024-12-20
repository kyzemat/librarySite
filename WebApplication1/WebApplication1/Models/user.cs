using System.ComponentModel.DataAnnotations;

namespace WebApplication1.Models
{
    public class user { 
        [Key]
        public int user_id { get; set; }
        public string username { get; set; }
        public string email { get; set; }
        public string password { get; set; }
        public string role { get; set; }
    }
}
