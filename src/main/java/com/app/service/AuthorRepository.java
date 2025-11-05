package com.app.service;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.app.entity.Author;

@Repository
public interface AuthorRepository extends JpaRepository<Author, Integer> {
    Author findByAuthorId(Integer authorId);
    Author findFirstByAuthorId(Integer authorId);
}
