#!/bin/bash

#pega o segundo(o primeiro e $0) flag digitado pelo user
OPTION_USER=$1
EMAIL=""
LOG_FILE="records_log.csv" #arquivo p salvar logs
#verifica e instala(caso necessario) pacotes necessarios
check_downloads(){
	echo "Verificando downloads..."
	sudo apt-get update
	# Verifica e instala powertop (energia)
	if ! command -v powertop &> /dev/null; then
        	echo "Instalando powertop..."
        	sudo apt-get install -y powertop
    	else
        	echo "powertop ja instalado"
        	echo "$(command -v powertop)"
    	fi

	# Verifica e instala mailutils (email)
	if ! command -v mail &> /dev/null; then
		echo "Instalando mailutils..."
		sudo apt-get install -y mailutils
	else
		echo "mailutils ja instalado"
		echo "$(command -v mailutils)"	
	fi
	#verifica e instala ssmtp (config email)
	if ! command -v ssmtp &> /dev/null; then
		echo "instalando ssmtp"
		sudo apt-get install -y ssmtp
	else
		echo "ssmtp ja instalado"
		echo "$(command -v ssmtp)"
	fi
	#verifica e instala systemctl (tela eco.)
	if ! command -v systemctl &> /dev/null; then
                echo "instalando symtemd"
                sudo apt-get install -y systemd
        else
                echo "systemd ja instalado"
                echo "$(command -v systemctl)"
        fi
	#verifica e instala iftop (rede)
	if ! command -v iftop &> /dev/null; then
		echo "instalando pacote iftop"
		sudo apt-get install -y iftop
	else
		echo "iftop ja instalado"
		echo "$(command -v iftop)"
	fi
	#verifica e instala mpstat (recursos)
	if ! command -v mpstat &> /dev/null; then
    		echo "mpstat não encontrado. Instalando sysstat..."
    		sudo apt-get install -y sysstat
	else
    		echo "mpstat já está instalado."
    		echo "$(command -v mpstat)"
	fi


}

#chama funcoes p execucao
process_perform(){
	case "$OPTION_USER" in
        	-e) 
           	    	monitoring_energy
            	;;
		--le)
		    	economy_energy
		;;
		-n)
			monitoring_network
		;;
		-r)
			monitoring_resources
		;;
        	-h)
        	    	help
            	;;
        	*)
            	    	echo "Opção inválida! Use -h para ajuda."
            	    	help
		    	exit 1
            	;;
    	esac
}
#monitorar trafego de rede
monitoring_network(){
	echo "Monitorando trafego de rede..."
	iftop -t -s 10 > report_network.txt
	echo "relatorio de trafego de rede gerado."
	send_email "Relatório trafego de rde" "Segue em anexo o relatório" report_network.txt
}

#monitorar uso de recursos do sistema
monitoring_resources(){
	echo "Monitorando uso de CPU, memoria e disco..."
	top -b -n 1 > use_resources.txt
	echo "Relatorio de uso de recursos gerado."
	send_email "Relatóriosobre o uso de recursos" "Segue em anexo o relatório" use_resources.txt
}

#funcao q monitora o consumo de energia
monitoring_energy(){
	echo "monitorando consumo de energia..."
	#verificando se existe um arquivo chamado energy_report.html
	if [[ -f "energy_report.html"  ]]; then
		echo "Arquivo energy_report.html existente sera removido..."
		rm energy_report.html
	fi
	#gera um novo relatorio de consumo de energia
	powertop --html=energy_report.html
	echo "relatorio gerado"
	send_email "Relatório de consumo de energia" "Segue em anexo o reatório"  "energy_report.html"
}

# Função para automatizar a economia de energia usando loginctl
economy_energy() {
    	local load_limit=0.1   # Limite de carga do sistema para suspender (padrão: 0.1)
    	local interval=6      # Intervalo de verificação em segundos

    	echo "Monitorando carga do sistema. Limite de carga para suspensão: $load_limit."
    	echo "Verificação a cada $interval segundos."

    	while true; do
        	# Obtém a carga média do sistema (1 minuto)
		current_load=$(awk '{print $1}' < /proc/loadavg)
        	# Verifica se a carga atual está abaixo do limite definido
        	if (( $(echo "$current_load < $load_limit" | bc -l) )); then
            		echo "$(date): Sistema com baixa atividade (carga: $current_load)."
	    		echo "Aplicando medidas de economia de energia..."
	    		# Suspender o sistema
            		echo "Sistema suspenso. Suspendendo..."
            		systemctl suspend

            		# Após suspensão, aguarda antes de hibernar
           	 	echo "Aguardando para hibernação..."
            		sleep 60

            		# Se a carga continuar baixa após a suspensão, entra em hibernação
            		current_load=$(awk '{print $1}' < /proc/loadavg)
            		if (( $(echo "$current_load < $load_limit" | bc -l) )); then
                		echo "$(date): Sistema ainda com baixa atividade. Entrando em hibernação..."
                		systemctl hibernate
            		else
                		echo "$(date): Sistema reativado após suspensão."
            		fi
        	else
            		echo "$(date): Sistema ativo (carga: $current_load)."
        	fi

        	# Espera o intervalo definido antes de verificar novamente
        	sleep "$interval"
    	done
}

#registrar dados ao executar alguma funcionalidade do codigo (exceto help e eco.de  energia)
log_data() {
    	echo "Registrando dados..."

    	# Verifica se o arquivo de log já existe, caso contrário, cria o cabeçalho
	if [ ! -f "$LOG_FILE" ]; then
        	echo "Timestamp,Tempo_Atividade,Uso_Memoria,Uso_CPU,Espaco_Disco" > "$LOG_FILE"
    	fi


	# Captura o tempo de atividade do sistema
    	UPTIME=$(uptime -p | sed "s/,/./g")
    	if [ -z "$UPTIME" ]; then
        	UPTIME="N/A"
	fi


    	# Captura o uso de memória
    	USE_MEMORY=$(free | grep "Mem" | awk '{print $3/$2 * 100.0}' | sed "s/,/./g")
    	if [ -z "$USE_MEMORY" ]; then
        	USE_MEMORY="N/A"
    	fi

    	# Captura o uso da CPU
       	USE_CPU=$(mpstat 1 1 | awk '/all/ {print 100 - $12}' | sed "s/,/./g" | head -n 1)
    	if [ -z "$USE_CPU" ]; then
        	USE_CPU="N/A"
    	fi

    	# Captura o espaço em disco (em % usado)
    	DISK_USAGE=$(df / | grep / | awk '{print $5}')
    	if [ -z "$DISK_USAGE" ]; then
        	DISK_USAGE="N/A"
    	fi


    	# Registrar os dados no arquivo
    	echo "$(date '+%Y-%m-%d %H:%M:%S'),$UPTIME,$USE_MEMORY,$USE_CPU,$DISK_USAGE" >> "$LOG_FILE"
    	echo "Dados registrados em ${LOG_FILE}..."
	echo "\"cat ${LOG_FILE}\" para visualizar"
}


# Configuração de SMTP para enviar email
smtp_config(){
    	echo "configurando smtp..."
    	echo "root=lansilvah14fsa@gmail.com" > /etc/ssmtp/ssmtp.conf
    	echo "mailhub=smtp.gmail.com:587" >> /etc/ssmtp/ssmtp.conf
    	echo "AuthUser=lansilvah14fsa@gmail.com" >> /etc/ssmtp/ssmtp.conf
    	echo "AuthPass=cneheauadwxkkqbz" >> /etc/ssmtp/ssmtp.conf
	echo "UseSTARTTLS=YES" >> /etc/ssmtp/ssmtp.conf # Criptografa a conexão com o servidor SMTP
  	echo "FromLineOverride=YES" >> /etc/ssmtp/ssmtp.conf  # Permite usar o email do campo From
}



# Função para enviar email
send_email(){
	local SUBJECT="$1"
    	local BODY="$2"
	local ATTACHMENT="$3"
    	local REMETENTE="lansilvah14fsa@gmail.com"

    	# Verifica se o anexo existe
    	if [ -n "$ATTACHMENT" ]; then #verifica se e uma string não vazia
       		if [ -f "$ATTACHMENT" ]; then #verifica se o arquivo existe
	    		echo "enviando email..."
            		echo "$BODY" | mail -s "$SUBJECT" -A "$ATTACHMENT" -r "$REMETENTE" "$EMAIL"
        	else
            		echo "Erro: O arquivo de anexo '$ATTACHMENT' não existe."
            		return 1
        	fi
    	else
        	echo "$BODY" | mail -s "$SUBJECT" -r "$REMETENTE" "$EMAIL"
    	fi

    	if [ $? -eq 0 ]; then #verifica se o codigo se saida é iguala a zero (sucesso)
        	echo "Email enviado com sucesso para $EMAIL."
    	else
        	echo "Erro ao enviar o email!"
    	fi
}



#funcao de ajuda
help(){
  	echo "Projeto de Monitoramento R&R"
	echo "Equipe: [Railan Santana e Raquel Oliveira]"
  	echo "Uso: $0 [-h] [-e] [-r] [-n] [--le]"
	echo "Opções:"
	echo "  -h    Resumo e uso do script"
	echo "  -e    Monitorar consumo de energia"
	echo "  -r    Monitorar uso de recursos"
	echo "  -n    Monitorar trafego de rede"
	echo "  --le  Ativar modo economia de energia"
}

validations(){
	if [[ $OPTION_USER == "-h" ]];then
                help
                exit 0 #retorno sucess
        fi
 
        if [[ $OPTION_USER == "" ]];then
                help
                exit 1 #retorno error
        fi

        if [[ $OPTION_USER != "--le"  ]];then
                read -p "Digite seu email: " EMAIL
        fi
}

#funcao principal
main(){
	clear
	validations
	clear
	echo "---------- configurando projeto -------------"
	check_downloads
	smtp_config
	echo "limpando tela..."
	sleep 1
	clear
	process_perform
	sleep 1
	clear
	if [[ $OPTION_USER != "-h" || $OPTION_USER != "--le"  ]];then
		echo "------------- salvando dados ----------------"
		log_data
		echo "---------------------------------------------"
	fi
}

main

