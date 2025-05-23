package com.demo.autoscaling_springboot_eks.Controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class EKSController {

    @GetMapping("/load")
    public String createCpuLoad() {
        long start = System.currentTimeMillis();
        while (System.currentTimeMillis() - start < 10000) {
            Math.pow(Math.random(), Math.random());
        }
        return "Load generated for 10 seconds!";
    }

    @GetMapping("/")
    public String hello() {
        return "Hello from EKS Spring Boot!";
    }
}