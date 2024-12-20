using Microsoft.EntityFrameworkCore;
using WebApplication1.Models;
namespace WebApplication1.DB;


public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
    }

    public DbSet<book> books { get; set; }
    public DbSet<user> Users { get; set; }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.Entity<user>().ToTable("users");
        // любые дополнительные настройки конфигурации
    }


}
