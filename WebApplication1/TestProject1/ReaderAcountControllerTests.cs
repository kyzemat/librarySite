using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using WebApplication1.Controllers;
using WebApplication1.Models;
using Xunit;
using Microsoft.AspNetCore.Http;
using WebApplication1.DB;

namespace WebApplication1.Tests
{
    public class ReaderAcountControllerTests : IDisposable
    {
        private DbContextOptions<ApplicationDbContext> _options;
        private ApplicationDbContext _context;

        public ReaderAcountControllerTests()
        {
            _options = new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseInMemoryDatabase(databaseName: "TestDb")
                .Options;
            _context = new ApplicationDbContext(_options);
        }

        [Fact]
        public async Task Index_AuthorizedUser_ReturnsViewWithUserData()
        {
            // Arrange
            var username = "testuser";
            var user = new user { username = username, password ="123321", email = "test@example.com", role = "reader" };
            _context.Users.Add(user);
            _context.SaveChanges();

            var controller = new ReaderAcountController(_context);

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, username)
            };
            var identity = new ClaimsIdentity(claims, "CookieAuth");
            var principal = new ClaimsPrincipal(identity);

            var httpContext = new Mock<HttpContext>();
            httpContext.Setup(x => x.User).Returns(principal);
            controller.ControllerContext = new ControllerContext { HttpContext = httpContext.Object };


            // Act
            var result = controller.Index() as ViewResult;

            // Assert
            Assert.NotNull(result);
            Assert.IsType<user>(result.Model);
            var viewUser = Assert.IsType<user>(result.Model);
            Assert.Equal(username, viewUser.username);
            Assert.Equal("test@example.com", viewUser.email);
            Assert.Equal("reader", viewUser.role);
        }

        public void Dispose()
        {
            _context.Dispose();
        }
    }
}