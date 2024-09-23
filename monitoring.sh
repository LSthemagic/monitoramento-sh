#!/bin/bash

#pega o flag digitado pelo user
OPTION_USER=$1
#boolean para monitorar energia
ENERGY_MONITOR=0
#boolean para monitorar temperatura
TEMP_MONITOR=0
#variavel para verificar limite de temperatura 
TEMP_LIMIT=$2

#verifica e instala(caso necessario) pacotes necessarios
check_downloads(){    
	echo "Verificando downloads..."
	sudo apt-get update
	# Verifica e instala powertop
	if ! command -v powertop &> /dev/null; then
        	echo "Instalando powertop..."
        	sudo apt-get install -y powertop
    	else
        	echo "powertop ja� instalado"
        	echo "$(command -v powertop)"
    	fi

    	# Verifica e instala lm-sensors
    	if ! command -v sensors &> /dev/null; then
        	echo "Instalando lm-sensors..."
        	sudo apt-get install -y lm-sensors
    	else
        	echo "lm-sensors ja� instalado"
        	echo "$(command -v sensors)"
    	fi

	# Verifica e instala mailutils
	if ! command -v mail &> /dev/null; then
		echo "Instalando mailutils..."
		sudo apt-get install -y mailutils
	else
		echo "mailutils ja instalado"
		echo "$(command -v mailutils)"	
	fi

}



cheks(){
	check_downloads
	if [[ $1 == "" ]]; then
		OPTION_USER="-h"
	fi
}

process_perform(){
   case "$OPTION_USER" in
        -e) 
            echo "Monitorando consumo de energia..."
            ENERGY_MONITOR=1
            ;;
        -t) 
            echo "Monitorando temperatura do sistema..."
            TEMP_MONITOR=1
            ;;
        -l) 
            # Verifica se foi fornecido um segundo argumento para o limite de temperatura
            if [[ -z "$TEMP_LIMIT" ]]; then
                echo "Erro: o limite de temperatura não foi fornecido."
                exit 1
            else
                echo "Definindo limite de temperatura: $TEMP_LIMIT"
            fi
            ;;
        -h)
            help
            ;;
        *)
            echo "Opção inválida! Use -h para ajuda."
            exit 1
            ;;
    esac
}

help(){
	echo " Resumo e uso do script com parâmetro -h"
#	if [[ $1 == "-h" || $1 == "--help" ]]; then
  		echo "Projeto de Monitoramento de Consumo de Energia e Temperatura"
  		echo "Uso: $0 [-h] [-e] [-t] [-l TEMP_LIMITE]"
  		echo "Opções:"
  		echo "  -e    Monitorar consumo de energia"
  		echo "  -t    Monitorar temperatura do sistema"
  		echo "  -l    Definir limite de temperatura para alertas"
		echo "Equipe: [Railan Santana e Raquel Oliveira]"
 # 	fi
}

main(){
	#cheks
	process_perform
}

main

