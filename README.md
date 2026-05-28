# Sistema Bancario Multicuenta y Multiproducto - BancoSeguro S.A.

Este repositorio contiene el diseño lógico, la arquitectura conceptual y la implementación física del sistema de bases de datos relacionales para **BancoSeguro S.A.** El proyecto ha sido desarrollado sobre el motor **Oracle 19c Enterprise Edition** utilizando un enfoque moderno de contenedorización y herramientas de desarrollo colaborativo en tiempo real.

## Descripción del Proyecto

El sistema está diseñado para soportar las operaciones de una institución financiera de gran escala (con más de 200,000 clientes activos y 50 sucursales). Centraliza y automatiza el ecosistema multiproducto del banco, el cual abarca:
* **Captación:** Cuentas de ahorros y cuentas corrientes (con gestión de sobregiros).
* **Colocación:** Préstamos de consumo/hipotecarios (tablas de amortización y pagos) y tarjetas de crédito revolventes.
* **Inversiones:** Pólizas a plazo fijo con penalizaciones parametrizadas.
* **Seguridad y Auditoría:** Control de accesos de usuarios, intentos fallidos y bitácora inmutable de operaciones.
* **Canales:** Transacciones concurrentes multicanal (Ventanilla, ATM, Web y Móvil).

---

## Arquitectura y Decisiones de Diseño

### Implementación de Herencia (Supertipo/Subtipo)
Se implementó el patrón de **Tabla por Clase (Especialización 1:1)** para la entidad `CLIENTE`. La tabla base centraliza los atributos globales (scoring, riesgo), mientras que las tablas hijas `PERSONA_NATURAL` y `PERSONA_JURIDICA` heredan la misma llave primaria (`id_cliente`), la cual actúa simultáneamente como clave foránea (FK). Este enfoque normalizado optimiza el espacio en disco, evita filas con valores nulos masivos (`NULL`) y permite la escalabilidad del modelo de negocio.

### Normalización de Contactos
Para dar cumplimiento a las reglas de negocio que exigen multiplicidad en los medios de contacto, los números telefónicos, direcciones y correos se extrajeron a tablas débiles secundarias (`TELEFONO_CLIENTE`, `DIRECCION_CLIENTE`). Se eliminó explícitamente la restricción `UNIQUE` sobre el campo del cliente en estas tablas para permitir relaciones de uno a muchos (1:N) fluidas.

---

## Infraestructura DevOps y Entorno Local

Para garantizar la paridad de entornos de desarrollo entre los 6 ingenieros del equipo, la base de datos se desplegó utilizando contenedores de **Docker** sobre el subsistema de Windows para Linux (**WSL2**).

### Despliegue del Contenedor
El motor de Oracle 19c se levanta mapeando el puerto estándar de comunicación hacia el host anfitrión:
```bash
docker run -d -p 1521:1521 --name oracle19c-bancoseguro [container-registry.oracle.com/database/enterprise:19.3.0.0](https://container-registry.oracle.com/database/enterprise:19.3.0.0)