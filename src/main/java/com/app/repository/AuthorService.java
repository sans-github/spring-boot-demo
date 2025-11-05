package com.app.repository;

import com.app.entity.Author;

public interface AuthorService {
    public Author findFirstByAuthorId(Integer authorId);
    public Author findByAuthorId(Integer authorId);
    public Author save(Author author);
}