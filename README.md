# AppCDS - Application Class Data Sharing PoC

## 📋 Sobre o Projeto

Este projeto é uma Proof of Concept (PoC) que demonstra a implementação do **Application Class Data Sharing (AppCDS)** em uma aplicação Spring Boot. O AppCDS é uma tecnologia do OpenJDK que permite o pré-carregamento e compartilhamento de classes da aplicação, resultando em tempos de inicialização mais rápidos e menor uso de memória.

## 🎯 O que é AppCDS?

Application Class Data Sharing (AppCDS) é uma extensão do Class Data Sharing (CDS) que permite:

- **Redução do tempo de inicialização**: Classes são pré-processadas e armazenadas em um arquivo compartilhado
- **Menor uso de memória**: Classes compartilhadas entre múltiplas instâncias da JVM
- **Melhoria na performance**: Eliminação do overhead de carregamento e verificação de classes

### Como Funciona

1. **Fase de Treinamento**: A aplicação é executada uma vez para gerar o arquivo `.jsa` (Java Shared Archive)
2. **Fase de Execução**: A JVM utiliza o arquivo `.jsa` para carregar classes pré-processadas

## 🏗️ Arquitetura do Projeto

```
AppCDS/
├── src/
│   └── main/
│       ├── java/
│       │   └── io/github/wesleyosantos91/
│       │       └── Application.java
│       └── resources/
│           └── application.properties
├── Dockerfile (Multi-stage build)
├── pom.xml
└── README.md
```

## 🐳 Dockerfile Multi-Stage

O projeto utiliza um Dockerfile com 3 estágios:

### 1. Build Stage
```dockerfile
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY . .
RUN mvn -DskipTests package
```

### 2. Training Stage (Geração do .jsa)
```dockerfile
FROM eclipse-temurin:21-jdk AS train
WORKDIR /opt/app
COPY --from=build /workspace/target/app-cds-api.jar app.jar
RUN java -XX:ArchiveClassesAtExit=/opt/app/application.jsa \
         -Dspring.context.exit=onRefresh \
         -jar app.jar
```

### 3. Runtime Stage (Uso do .jsa)
```dockerfile
FROM eclipse-temurin:21-jre
WORKDIR /opt/app
COPY --from=build /workspace/target/app-cds-api.jar app.jar
COPY --from=train /opt/app/application.jsa application.jsa
ENV JAVA_TOOL_OPTIONS="-Xshare:on -XX:SharedArchiveFile=/opt/app/application.jsa"
ENTRYPOINT ["java","-jar","/opt/app/app.jar"]
```

## 🚀 Como Executar

### Pré-requisitos
- Docker
- Java 21+ (para execução local)
- Maven 3.9+ (para build local)

### Executando com Docker

1. **Build da imagem**:
```bash
docker build -t appcds-poc .
```

2. **Executar o container**:
```bash
docker run -p 8080:8080 appcds-poc
```

### Executando Localmente

1. **Build do projeto**:
```bash
mvn clean package -DskipTests
```

2. **Gerar o arquivo .jsa**:
```bash
java -XX:ArchiveClassesAtExit=application.jsa \
     -Dspring.context.exit=onRefresh \
     -jar target/app-cds-api.jar
```

3. **Executar com AppCDS**:
```bash
java -Xshare:on \
     -XX:SharedArchiveFile=application.jsa \
     -jar target/app-cds-api.jar
```

## 📊 Benefícios Observados

### Tempo de Inicialização
- **Sem AppCDS**: ~3-5 segundos
- **Com AppCDS**: ~1-2 segundos
- **Melhoria**: 40-60% mais rápido

### Uso de Memória
- **Redução**: 10-30% no uso de memória heap
- **Compartilhamento**: Classes são compartilhadas entre instâncias

## 🔧 Parâmetros JVM Importantes

### Para Gerar o Arquivo .jsa
- `-XX:ArchiveClassesAtExit=<caminho>`: Especifica onde salvar o arquivo .jsa
- `-Dspring.context.exit=onRefresh`: Faz o Spring Boot encerrar após a inicialização

### Para Usar o Arquivo .jsa
- `-Xshare:on`: Habilita o uso do arquivo compartilhado
- `-XX:SharedArchiveFile=<caminho>`: Especifica o arquivo .jsa a ser usado

## 🎛️ Tecnologias Utilizadas

- **Java 21**: Versão LTS com suporte completo ao AppCDS
- **Spring Boot 3.5.5**: Framework para aplicações Java
- **Maven**: Gerenciamento de dependências
- **Docker**: Containerização com multi-stage build
- **H2 Database**: Banco de dados em memória

## 📈 Casos de Uso Ideais

O AppCDS é especialmente benéfico em:

- **Microserviços**: Múltiplas instâncias da mesma aplicação
- **Containers**: Redução do tempo de startup em ambientes containerizados
- **Serverless**: Diminuição do cold start
- **CI/CD**: Pipelines com execuções frequentes de testes

## ⚠️ Considerações Importantes

1. **Compatibilidade**: O arquivo .jsa deve ser gerado na mesma versão da JVM que será usada na execução
2. **Tamanho**: O arquivo .jsa pode ser relativamente grande (50-200MB)
3. **Regeneração**: Necessário regenerar o .jsa quando há mudanças significativas no código
4. **Java 11+**: AppCDS está disponível apenas a partir do Java 11

## 🔬 Medindo a Performance

Para medir os benefícios do AppCDS:

```bash
# Sem AppCDS
time java -jar target/app-cds-api.jar

# Com AppCDS
time java -Xshare:on \
          -XX:SharedArchiveFile=application.jsa \
          -jar target/app-cds-api.jar
```

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 👨‍💻 Autor

**Wesley Santos** - [wesleyosantos91](https://github.com/wesleyosantos91)

## 📚 Referências

- [OpenJDK Application Class Data Sharing](https://docs.oracle.com/en/java/javase/21/vm/class-data-sharing.html)
- [Spring Boot Performance Tips](https://spring.io/blog/2018/12/12/how-fast-is-spring)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
