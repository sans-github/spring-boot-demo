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
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import jakarta.validation.constraints.NotNull;

@RestController
@RequestMapping("/author")
public class AuthorController {
	@Autowired
	private AuthorService authorService; 

	private Gson gson = new GsonBuilder().setPrettyPrinting().create();

	@GetMapping
	public String firstFindById(@RequestParam("author_id") Integer authorId) {
		Author author = authorService.findFirstByAuthorId(authorId);
		return gson.toJson(author);
	}

	@PostMapping
	public String saveAuthor(@RequestBody @NotNull Author author) {
		Author authorSaved = authorService.save(author);
		return gson.toJson(authorSaved);
	}
}