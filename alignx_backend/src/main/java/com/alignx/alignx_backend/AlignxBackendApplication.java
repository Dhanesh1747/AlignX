package com.alignx.alignx_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication(scanBasePackages = "com.alignx.alignx_backend")
@RestController
public class AlignxBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(AlignxBackendApplication.class, args);
    }

    @GetMapping("/test")
    public String testRoute() {
        return "Backend is active and routing works!";
    }
}S