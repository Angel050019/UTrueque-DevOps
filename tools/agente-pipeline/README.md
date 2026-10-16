# Agente del Pipeline CI - UTrueque

Página web que **observa el pipeline de GitHub Actions** del proyecto, **dibuja cada paso** mientras avanza y **explica en español** lo que pasa: qué hace cada paso, cuánto suele tardar, si va lento, por qué falló y qué hacer para arreglarlo.

No necesita instalar nada: es un solo archivo (`index.html`) que corre en el navegador.

## Cómo abrirlo

**Opción 1 (la más fácil):** abre `tools/agente-pipeline/index.html` con doble clic. Se abre en Chrome o Edge.

**Opción 2 (servidor local):** desde la raíz del repo, en Git Bash:

```bash
python -m http.server 8000
# luego abre http://localhost:8000/tools/agente-pipeline/
```

Al abrirlo, el agente se conecta solo a `Angel050019/UTrueque-DevOps` y empieza a seguir la corrida más reciente del workflow `ci.yml`.

## Token de GitHub (opcional)

- **Sin token:** GitHub permite 60 consultas por hora. Alcanza para ver una corrida, pero puede quedarse corto si la dejas abierta mucho tiempo.
- **Con token:** el límite sube a 5000 consultas por hora y se activa el botón **Lanzar pipeline**.

Para crearlo: GitHub → *Settings → Developer settings → Personal access tokens → Tokens (classic)* → *Generate new token*.

- Para solo **ver** el pipeline basta un token **sin permisos marcados**.
- Para **lanzar** el pipeline desde el agente, marca el permiso `repo`. Tu usuario también debe tener permiso de escritura en el repo (los colaboradores lo tienen).

Pégalo en **Ajustes de conexión → Token** y presiona **Conectar**. El token se guarda solo en esa pestaña del navegador y se borra al cerrarla. **Nunca lo escribas en el código ni lo subas al repositorio.**

## ¿Por qué es un agente?

Funciona en un ciclo continuo de **percibir → razonar → actuar**.

| Etapa | Qué hace |
| --- | --- |
| **Percibir** | Consulta la API REST de GitHub Actions: corridas del workflow, jobs, pasos (con su estado y tiempos) y anotaciones del CI (`::warning`, `::error`). Ajusta la frecuencia: cada 3 s si hay una corrida en curso, cada 15–20 s si no. |
| **Recordar y aprender** | Guarda el estado anterior de cada paso para detectar cambios. Aprende cuánto tarda normalmente cada paso a partir de las últimas corridas exitosas. |
| **Razonar** | Compara lo nuevo con lo anterior y con lo aprendido: <br>• detecta pasos que empiezan, terminan, fallan o se omiten; <br>• calcula el avance y el tiempo restante; <br>• avisa si un paso tarda más del doble de lo normal; <br>• cruza las fallas con su base de conocimiento (qué hace cada paso y qué hacer si falla). |
| **Actuar** | Dibuja el riel de pasos y la barra de avance, narra en la bitácora, lee en voz alta los momentos importantes (botón **Voz**), muestra un diagnóstico con enlaces a GitHub y SonarQube Cloud y, con permiso, **lanza el pipeline** (`workflow_dispatch`). |

## Qué muestra la pantalla

- **Encabezado:** commit, número de corrida, evento (push, pull request o lanzado a mano), rama, autor, reloj y tiempo restante estimado.
- **Pasos del pipeline:** cada paso es una estación.
  - Verde: terminó bien.
  - Verde claro y latiendo: en curso.
  - Rojo: falló.
  - Punteado: se omitió.
  - El tramo de vía se llena según el avance del paso en curso.
- **Lo que observa el agente:** un diagnóstico de la situación actual y la bitácora con todo lo que fue detectando, con hora.
- **Corridas recientes:** puedes elegir cualquier corrida anterior para revisarla.
- **Repetir esta corrida:** reproduce una corrida ya terminada con sus **tiempos reales** a 1×, 2×, 4× u 8×, con la narración completa. Sirve para el video si no alcanzas a grabar una corrida en vivo. La pantalla indica claramente que es una repetición.

## Cómo grabar el video de evidencia

1. Abre el agente y pon tu token en *Ajustes de conexión*.
2. Empieza a grabar la pantalla: barra de juegos de Windows con `Win + Alt + R`, o OBS.
3. Presiona **Lanzar pipeline** y escribe `develop`. También sirve hacer push a una rama con PR abierto, o usar el botón *Run workflow* en la pestaña Actions de GitHub.
4. Activa **Voz** si quieres que el agente narre en voz alta.
5. Deja que se vea cómo avanza cada paso hasta "Pipeline en verde" con el Quality Gate de SonarQube.
6. Opcional: muestra una corrida que falló, eligiéndola en *Corridas recientes*, para enseñar el diagnóstico del agente.

## Parámetros en la URL

`index.html?repo=dueño/repo&workflow=ci.yml&velocidad=4` permite usar el agente con otro repositorio o workflow.
