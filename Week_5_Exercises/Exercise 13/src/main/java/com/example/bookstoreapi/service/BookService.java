package com.example.bookstoreapi.service;

import com.example.bookstoreapi.model.Book;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class BookService {

    private List<Book> books = new ArrayList<>();
    private long nextId = 1L;

    // Method to create a new book
    public Book createBook(Book book) {
        book.setId(nextId++);
        books.add(book);
        return book;
    }

    // Method to find all books
    public List<Book> findAllBooks() {
        return new ArrayList<>(books);
    }

    // Method to find a book by ID
    public Book findBookById(Long id) {
        return books.stream()
                .filter(book -> book.getId().equals(id))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Book not found with ID " + id));
    }

    // Method to update a book
    public Book updateBook(Long id, Book updatedBook) {
        Book book = findBookById(id);
        book.setTitle(updatedBook.getTitle());
        book.setAuthor(updatedBook.getAuthor());
        book.setPrice(updatedBook.getPrice());
        book.setIsbn(updatedBook.getIsbn());
        return book;
    }

    // Method to delete a book
    public void deleteBook(Long id) {
        books.removeIf(book -> book.getId().equals(id));
    }
}
