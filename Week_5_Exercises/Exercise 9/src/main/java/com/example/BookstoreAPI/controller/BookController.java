package com.example.BookstoreAPI.controller;

import com.example.BookstoreAPI.assembler.BookResourceAssembler;
import com.example.BookstoreAPI.model.Book;
import com.example.BookstoreAPI.repository.BookRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.hateoas.CollectionModel;
import org.springframework.hateoas.EntityModel;
import org.springframework.hateoas.Link;
import org.springframework.hateoas.server.mvc.WebMvcLinkBuilder;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/books")
public class BookController {

    @Autowired
    private BookRepository bookRepository;

    @Autowired
    private BookResourceAssembler assembler;

    @GetMapping
    public ResponseEntity<CollectionModel<EntityModel<Book>>> getAllBooks() {
        List<EntityModel<Book>> books = bookRepository.findAll().stream()
                .map(assembler::toModel)
                .collect(Collectors.toList());

        Link selfLink = WebMvcLinkBuilder.linkTo(WebMvcLinkBuilder.methodOn(BookController.class).getAllBooks()).withSelfRel();
        return ResponseEntity.ok(CollectionModel.of(books, selfLink));
    }

    @PostMapping
    public ResponseEntity<EntityModel<Book>> createBook(@RequestBody @Valid Book book) {
        Book savedBook = bookRepository.save(book);
        EntityModel<Book> bookModel = assembler.toModel(savedBook);
        return ResponseEntity.status(HttpStatus.CREATED).body(bookModel);
    }

    @GetMapping("/{isbn}")
    public ResponseEntity<EntityModel<Book>> getBook(@PathVariable String isbn) {
        Optional<Book> book = bookRepository.findById(Long.valueOf(isbn));
        return book.map(b -> ResponseEntity.ok(assembler.toModel(b)))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND).build());
    }

    @PutMapping("/{isbn}")
    public ResponseEntity<EntityModel<Book>> updateBook(@PathVariable String isbn, @Valid @RequestBody Book updatedBook) {
        return bookRepository.findById(Long.valueOf(isbn))
                .map(book -> {
                    book.setTitle(updatedBook.getTitle());
                    book.setAuthor(updatedBook.getAuthor());
                    book.setPrice(updatedBook.getPrice());
                    Book updated = bookRepository.save(book);
                    return ResponseEntity.ok(assembler.toModel(updated));
                })
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{isbn}")
    public ResponseEntity<Object> deleteBook(@PathVariable String isbn) {
        return bookRepository.findById(Long.valueOf(isbn))
                .map(book -> {
                    bookRepository.delete(book);
                    return ResponseEntity.noContent().build(); // Return 204 No Content on successful deletion
                })
                .orElseGet(() -> ResponseEntity.notFound().build()); // Return 404 Not Found if book is not present
    }
}
