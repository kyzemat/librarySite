using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApplication1.DB;

namespace WebApplication1.Controllers
{
    public class BooksController : Controller
    {
        private readonly ApplicationDbContext _context;

        public BooksController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: /Books
        public async Task<IActionResult> Index()
        {
            var books = await _context.books.ToListAsync();
            return View(books);
        }

        public IActionResult Details(int id)
        {
            var book = _context.books.FirstOrDefault(b => b.book_id == id); // Ищем книгу по ID
            if (book == null)
            {
                return NotFound(); // Если книга не найдена, возвращаем 404
            }
            return View(book);
        }
    }
}
