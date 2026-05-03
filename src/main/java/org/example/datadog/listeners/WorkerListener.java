package org.example.datadog.listeners;

import com.fasterxml.jackson.databind.ObjectMapper;
import datadog.trace.api.Trace;
import io.awspring.cloud.sqs.annotation.SqsListener;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.ThreadContext;
import org.example.datadog.exceptions.QueueProcessingException;
import org.springframework.stereotype.Component;

@Component
public class WorkerListener {

    private static final Logger log = LogManager.getLogger(WorkerListener.class);
    private final ObjectMapper mapper = new ObjectMapper();

    @SqsListener("worker-queue-1")
    @Trace(operationName = "listener.process.queue1", resourceName = "worker-queue-1")
    public void listenQueue1(String message) {

        ThreadContext.put("listener_type", "queue1");

        try {
            var outer = mapper.readTree(message);

            // SNS encapsula mensagem
            var inner = mapper.readTree(outer.get("Message").asText());

            String eventType = inner.get("event").asText();
            ThreadContext.put("event_type", eventType);

            log.atInfo()
                    .log("Mensagem recebida - event_type={} raw_message={}", eventType, message);

        } catch (Exception e) {
            log.atError()
                    .log("Erro ao processar mensagem - raw_message={}", message);
            throw new QueueProcessingException("Falha no processamento da fila 1", e);
        } finally {
            ThreadContext.clearAll();
        }
    }
}