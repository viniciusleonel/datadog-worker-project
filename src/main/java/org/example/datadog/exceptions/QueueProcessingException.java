package org.example.datadog.exceptions;

public class QueueProcessingException extends RuntimeException {

    public QueueProcessingException(String message) {
        super(message);
    }

    public QueueProcessingException(String message, Throwable cause) {
        super(message, cause);
    }
}