package org.example.datadog.listeners;

import com.fasterxml.jackson.databind.ObjectMapper;
import datadog.trace.api.Trace;
import io.awspring.cloud.sqs.annotation.SqsListener;
import software.amazon.awssdk.services.sqs.model.Message;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.ThreadContext;
import org.example.datadog.exception.QueueProcessingException;
import org.example.datadog.service.SqsService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class WorkerListener2 {

    private static final Logger log = LogManager.getLogger(WorkerListener2.class);
    private final ObjectMapper mapper = new ObjectMapper();
    private final SqsService sqsService;
    private final String queue1;

    public WorkerListener2(SqsService sqsService, @Value("${spring.cloud.aws.sqs.queue1}") String queue1) {
        this.sqsService = sqsService;
        this.queue1 = queue1;
    }
    @SqsListener("worker-queue-1")
    @Trace(operationName = "listener.process.queue2", resourceName = "worker-queue-2")
    public void listenQueue1(Message message) {

        log.atInfo()
                .log("Mensagem recebida - raw_message={}",  message);

        ThreadContext.put("listener_type", "queue2");

        try {
            var outer = mapper.readTree(message.body());
            var inner = mapper.readTree(outer.get("Message").asText());

            String eventType = inner.get("event").asText();
            String status = inner.get("status").asText();

            ThreadContext.put("event_type", eventType);

            if ("ERROR".equals(status)) {
                throw new RuntimeException("Erro simulado");
            }

            log.atInfo()
                    .log("Mensagem processada da queue2 - event_type={} raw_message={}", eventType, message);
            sqsService.deleteMessage(queue1, message.receiptHandle());
        } catch (Exception e) {
            log.atError()
                    .log("Erro ao processar mensagem - raw_message={}", message);
            throw new QueueProcessingException("Falha no processamento da fila 2", e);
        } finally {
            ThreadContext.clearAll();
        }
    }
}