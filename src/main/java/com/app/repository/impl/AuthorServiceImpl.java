package com.app.repository.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.app.entity.Author;
import com.app.repository.AuthorService;
import com.app.service.AuthorRepository;

@Service
public class AuthorServiceImpl implements AuthorService {

    @Autowired
    private AuthorRepository authorRepository;

    public Author findByAuthorId(Integer authorId) {
        return authorRepository.findByAuthorId(authorId);
    }

    public Author findFirstByAuthorId(Integer authorId){
        return authorRepository.findFirstByAuthorId(authorId);
    }

    public Author save(Author author){
        return authorRepository.save(author);
    }
}
