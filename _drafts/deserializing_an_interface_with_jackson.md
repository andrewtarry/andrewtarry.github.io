# Deserializing an interface with jackson

Jackson is my favorite library for mapping Json to a Java object and most of the time it can map your objects to a POJO but when using interfaces it takes a bit more work.

## Scenario 1: when you control the interface and there is only one implementation

This is one of the most simple scenarios because there is only one possible implementation of the interface. 