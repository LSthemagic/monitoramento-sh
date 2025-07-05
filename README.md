# Projeto de Monitoramento R&R

Script em **BASH** para monitorar consumo de energia, uso de recursos e tráfego de rede em sistemas Linux (Debian/Ubuntu), além de oferecer um modo de economia de energia automática e envio de relatórios por e-mail.

---

## Índice

- [Pré-requisitos](#pré-requisitos)  
- [Instalação](#instalação)  
- [Uso](#uso)  
  - [Opções](#opções)  
  - [Exemplos](#exemplos)  
- [Como Funciona](#como-funciona)  
  - [Verificação e instalação de pacotes](#verificação-e-instalação-de-pacotes)  
  - [Monitoramento de energia](#monitoramento-de-energia)  
  - [Modo economia de energia](#modo-economia-de-energia)  
  - [Monitoramento de recursos](#monitoramento-de-recursos)  
  - [Monitoramento de rede](#monitoramento-de-rede)  
  - [Registro de logs](#registro-de-logs)  
  - [Envio de e-mail](#envio-de-e-mail)  
- [Equipe](#equipe)  
- [Licença](#licença)  

---

## Pré-requisitos

- **Sistema operacional:** Debian, Ubuntu ou derivados  
- **Permissões:** usuário com privilégios `sudo`  
- **Dependências internas (serão instaladas automaticamente):**  
  - `powertop`  
  - `mailutils`  
  - `ssmtp`  
  - `systemd`  
  - `iftop`  
  - `sysstat` (para `mpstat`)  

---

## Instalação

1. Clone o repositório ou copie o script para sua máquina:
   ``
   git clone https://seu-repositorio.git
   cd seu-repositorio
   chmod +x monitor.sh
``

2. Certifique-se de que o script tenha permissão de execução:

   ```
   chmod +x monitor.sh
   ```

---

## Uso

```
./monitor.sh [OPÇÃO]
```

### Opções

| Opção  | Descrição                                                             |
| ------ | --------------------------------------------------------------------- |
| `-h`   | Exibe ajuda e uso do script                                           |
| `-e`   | Monitora consumo de energia e envia relatório HTML                    |
| `--le` | Ativa o modo de economia de energia (suspensão/hibernação automática) |
| `-r`   | Monitora uso de CPU, memória e disco                                  |
| `-n`   | Monitora tráfego de rede por 10 segundos                              |

### Exemplos

* **Ajuda**

  ```
  ./monitor.sh -h
  ```

* **Relatório de energia**

  ```
  ./monitor.sh -e
  ```

* **Economia de energia automática**

  ```
  ./monitor.sh --le
  ```

* **Uso de recursos**

  ```
  ./monitor.sh -r
  ```

* **Tráfego de rede**

  ```
  ./monitor.sh -n
  ```

---

## Como Funciona

### Verificação e instalação de pacotes

Ao iniciar, a função `check_downloads()` atualiza os repositórios (`apt-get update`) e instala, se necessário, os pacotes listados:

* `powertop`
* `mailutils`
* `ssmtp`
* `systemd`
* `iftop`
* `sysstat` (para fornecer `mpstat`)

### Monitoramento de energia

Função `monitoring_energy()`:

1. Remove relatório antigo (`energy_report.html`).
2. Gera novo relatório com `powertop --html=energy_report.html`.
3. Envia por e-mail o arquivo HTML gerado.

### Modo economia de energia

Função `economy_energy()`:

* Monitora a carga média de 1 minuto em `/proc/loadavg`.
* Se a carga cair abaixo de `0.1`, executa:

  1. `systemctl suspend`
  2. Após 60 s, verifica carga novamente
  3. Se ainda baixa, executa `systemctl hibernate`

Loop infinito com verificação a cada 6 segundos.

### Monitoramento de recursos

Função `monitoring_resources()`:

1. Captura uso de CPU, memória e disco com `top -b -n 1`.
2. Salva em `use_resources.txt`.
3. Envia relatório por e-mail.

### Monitoramento de rede

Função `monitoring_network()`:

1. Captura tráfego por 10 s com `iftop -t -s 10`.
2. Salva em `report_network.txt`.
3. Envia relatório por e-mail.

### Registro de logs

Função `log_data()` (para todas as operações, exceto `-h`/`--le`):

* Gera (se necessário) o arquivo `records_log.csv` com cabeçalho:

  ```
  Timestamp,Tempo_Atividade,Uso_Memoria,Uso_CPU,Espaco_Disco
  ```
* Em cada execução registra:

  * Data/hora
  * `uptime -p` (tempo de atividade)
  * Uso de memória (%)
  * Uso de CPU (%) via `mpstat`
  * Espaço em disco (`df /`)

### Envio de e-mail

1. Configuração de SMTP em `/etc/ssmtp/ssmtp.conf` via `smtp_config()`.
2. Função `send_email()` recebe:

   * **Assunto**
   * **Corpo**
   * **Anexo** (opcional)
3. Envia usando `mail -s … -A … -r remetente …`.

---

## Equipe

* **Railan Santana**
* **Raquel Oliveira**

---

## Licença

Este projeto está licenciado sob a **MIT License**. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.
