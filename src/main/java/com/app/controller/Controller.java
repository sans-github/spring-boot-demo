package com.app.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.app.model.Author;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import jakarta.validation.constraints.NotNull;

@RestController
public class Controller {

	@GetMapping("/get-it")
	public String getIt() {
		return "Yes, I get it";
	}

	@PostMapping("/post-it")
	public String postIt(@RequestBody @NotNull Author author) {
		Gson gson = new GsonBuilder().setPrettyPrinting().create();
		return gson.toJson(author);
	}
}