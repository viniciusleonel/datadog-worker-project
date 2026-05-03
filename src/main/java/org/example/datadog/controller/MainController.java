package org.example.datadog.controller;

import lombok.extern.slf4j.Slf4j;
import org.example.datadog.model.dto.Coffee;
import org.example.datadog.model.dto.DataResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Slf4j
public class MainController {

    @GetMapping()
    public DataResponse get () {

        log.info("Recebendo get");
        return new DataResponse("Hello World!");
    }

    @PostMapping
    public Coffee post (@RequestBody Coffee coffee) {

        log.info("Recebendo post");
        return coffee;
    }
}
