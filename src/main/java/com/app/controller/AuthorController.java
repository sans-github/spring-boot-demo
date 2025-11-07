package com.app.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.app.entity.Author;
import com.app.repository.AuthorService;

import jakarta.validation.constraints.NotNull;

@RestController
@RequestMapping("/author")
public class AuthorController {
	@Autowired
	private AuthorService authorService; 

	@GetMapping
	public Author firstFindById(@RequestParam("author_id") Integer authorId) {
		return authorService.findFirstByAuthorId(authorId);
	}

	@PostMapping
	public Author saveAuthor(@RequestBody @NotNull Author author) {
		return authorService.save(author);
	}
}