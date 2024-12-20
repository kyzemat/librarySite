    using Microsoft.AspNetCore.Mvc;
    using Microsoft.EntityFrameworkCore;
using Moq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using WebApplication1.Controllers;
using WebApplication1.DB;
using WebApplication1.Models;
using Xunit;

namespace WebApplication1.Tests
{
    [Collection("Sequential")]
    public class BooksControllerTests
    {


        private ApplicationDbContext GetContext()
        {
            var options = new DbContextOptionsBuilder<ApplicationDbContext>()
                 .UseInMemoryDatabase(databaseName: "TestDb")
                 .Options;
            return new ApplicationDbContext(options);

        }

        [Fact]
        public async Task Index_ReturnsBookName()
        {

            using(var context = GetContext()) { 
                context.books.AddRange(new List<book> {
                    new book { name = "Book 1", description = "1", isbn = "123", path_to_book_cover=""},
                    new book { name = "Book 2", description = "2", isbn = "321", path_to_book_cover = ""}
                });
            context.SaveChanges();




            var controller = new BooksController(context);

            // Act (Действие)
            var result = await controller.Index() as ViewResult;
            var model = result?.Model as List<book>;

            // Assert (Проверка)
            Assert.NotNull(result);
            Assert.NotNull(model);
            Assert.Contains(model, b => b.name == "Book 1");
            Assert.Contains(model, b => b.name == "Book 2");
            }
        }

        [Fact]
        public async Task Index_ReturnsBookPath()
        {

            using (var context = GetContext())
            {
                context.books.AddRange(new List<book> {
                    new book { name = "Book 3", description = "3", isbn = "123", path_to_book_cover="../../img/books/idiot.jpg"},
                    new book { name = "Book 4", description = "4", isbn = "321", path_to_book_cover = "../../img/books/zemlya.jpg"}
                });
                context.SaveChanges();




                var controller = new BooksController(context);

                // Act (Действие)
                var result = await controller.Index() as ViewResult;
                var model = result?.Model as List<book>;

                // Assert (Проверка)
                Assert.NotNull(result);
                Assert.NotNull(model);
                Assert.Contains(model, b => b.path_to_book_cover == "../../img/books/idiot.jpg");
                Assert.Contains(model, b => b.path_to_book_cover == "../../img/books/zemlya.jpg");
            }
        }

        [Fact]
        public void Details_ReturnsViewWithBook()
        {
            using (var context = GetContext())
            {

                // Заполняем тестовую базу данных
                var book = new book { name = "Book 5", description = "5", isbn = "3211", path_to_book_cover = "" };
        context.books.Add(book);
                context.SaveChanges();


                var controller = new BooksController(context);
        var id = book.book_id;
        // Act
        var result = controller.Details(id) as ViewResult;
        var model = result?.Model as book;

        // Assert
        Assert.NotNull(result);
                Assert.NotNull(model);
                Assert.Equal("Book 5", model.name);
            }
        }

        [Fact]
        public void Details_ReturnsViewWithDescription()
        {
            using (var context = GetContext())
            {

                // Заполняем тестовую базу данных
                var book = new book { name = "Book 6", description = "Описание книги", isbn = "3211", path_to_book_cover = "" };
                context.books.Add(book);
                context.SaveChanges();


                var controller = new BooksController(context);
                var id = book.book_id;
                // Act
                var result = controller.Details(id) as ViewResult;
                var model = result?.Model as book;

                // Assert
                Assert.NotNull(result);
                Assert.NotNull(model);
                Assert.Equal("Описание книги", model.description);
            }
        }

        [Fact]
        public void Details_ReturnsViewWithIsbn()
        {
            using (var context = GetContext())
            {

                // Заполняем тестовую базу данных
                var book = new book { name = "Book 7", description = "Описание книги", isbn = "3211", path_to_book_cover = "" };
                context.books.Add(book);
                context.SaveChanges();


                var controller = new BooksController(context);
                var id = book.book_id;
                // Act
                var result = controller.Details(id) as ViewResult;
                var model = result?.Model as book;

                // Assert
                Assert.NotNull(result);
                Assert.NotNull(model);
                Assert.Equal("3211", model.isbn);
            }
        }

        [Fact]
        public void Details_NonExistingBookId_ReturnsNotFound()
        {
            // Arrange
            using (var context = GetContext())
            {
                var controller = new BooksController(context);

                // Act
                var result = controller.Details(999);

                // Assert
                Assert.IsType<NotFoundResult>(result);
            }
        }


    }
}