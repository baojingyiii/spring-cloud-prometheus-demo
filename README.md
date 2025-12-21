# spring boot + prometheus

使用spring boot编写一个简单的应用，并使用prometheus监控

### 简略步骤
1. `docker build -f Dockerfile -t boot-app:v1.0 .`
2. `docker run -d -p 8080:8080 --name boot boot-app:v1.0`
3. `docker compose -f compose.yml up -d`


> 注：
>
> （1）prometheus.yml文件位置应与compose.yml中填写的位置一致（`/app/prom/conf/prometheus.yml`）
>
> （2）基于java17，dockerfile的位置应与`COPY target/*.jar /app/boot.jar`的内容对应

***

### 详细步骤

#### 一、创建spring boot：

创建object后选择依赖(spring web / spring boot actuator / prometheus)

以下是一个简易的hello.java

```java
package com.baojingyi.prom.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {
    @GetMapping("/hello")
    public String Hello(){
        return "hello";

    }

}
```

运行后访问网页http://localhost:8080/hello




在`application.properties`添加

`management.endpoints.web.exposure.include=*` 暴露所有监控指标

使用maven编译，会产生一个jar包`spring-cloud-prometheus-demo-0.0.1-SNAPSHOT.jar`

***

#### 二、编写dockerfile

```dockerfile
FROM openjdk:17
COPY target/*.jar /app/boot.jar   //注意实际jar包的位置
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/boot.jar"]
```

构建镜像:

`docker build -f Dockerfile -t boot-app:v1.0 .`

运行app:

`docker run -d -p 8080:8080 --name boot boot-app:v1.0`

> 到此myapp创建完毕

***

#### 三、编写prometheus配置文件

```yaml
#prometheus.yml
global:
  scrape_interval: 15s 
  evaluation_interval: 15s 
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'bootapp-exporter'     //myapp的exporter
    metrics_path: '/actuator/prometheus'     //myapp的指标：springboot通过actuator暴露
    static_configs:
    - targets: ['172.26.242.116:8080']   //内网ip
      labels: 
        appname: 'bootapp'
```

#### 四、编写compose.yml

```yaml
name: prom
services:
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    restart: always
    volumes:
      - /app/prom/conf/prometheus.yml:/etc/prometheus/prometheus.yml   
                                                        //注意实际的prometheus.yml的位置
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "9090:9090"
    networks:
      - backend
  grafana:
    image: grafana/grafana
    container_name: grafana
    restart: always
    volumes:
      - /etc/localtime:/etc/localtime:ro
    depends_on:
      - prometheus
    ports:
      - "3000:3000"
    networks:
      - backend
networks:
  backend:
    name: backend
```

启动容器：

`docker compose -f compose.yml up -d`

> 到此`prometheus` + `grafana` 有了




***

#### 五、grafana连接prometheus

登录grafana，在data sources中连接prometheus

