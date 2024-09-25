#!/bin/bash



#pega o primeiro  flag digitado pelo user
OPTION_USER=$1
EMAIL=""

#verifica e instala(caso necessario) pacotes necessarios
check_downloads(){    
        echo "Verificando downloads..."
        #sudo apt-get update
        # Verifica e instala powertop
        if ! command -v powertop &> /dev/null; then
                echo "Instalando powertop..."
                sudo apt-get install -y powertop
        else
                echo "powertop ja� instalado"
                echo "$(command -v powertop)"
        fi

        # Verifica e instala mailutils
        if ! command -v mail &> /dev/null; then
                echo "Instalando mailutils..."
                sudo apt-get install -y mailutils
        else
                echo "mailutils ja instalado"
                echo "$(command -v mailutils)"
        fi

        if ! command -v ssmtp &> /dev/null; then
                echo "instalando ssmtp"
                sudo apt-get install -y ssmtp
        else
                echo "ssmtp ja instalado"
                echo "$(command -v ssmtp)"
        fi

        if ! command -v xprintidle &> /dev/null; then
                echo "instalando xprintidles"
                sudo apt-get install -y xprintidle
        else
                echo "xprintidle ja instalado"
                echo "$(command -v xprintidle)"
        fi

        if ! command -v xset &> /dev/null; then
                echo "instalando ssmtp"
                sudo apt-get install -y x11-xserver-utils
        else
                echo "xset ja instalado"
                echo "$(command -v xset)"
        fi
        if ! command -v systemctl &> /dev/null; then
                echo "instalando symtemd"
                sudo apt-get install -y systemd
        else
                echo "systemd ja instalado"
                echo "$(command -v systemctl)"
        fi

}



cheks(){
        if [[ $OPTION_USER == "" ]]; then
                help
                exit 1
        fi
        check_downloads
}


process_perform(){
        case "$OPTION_USER" in
                -e) 
                    monitoring_energy
                ;;
                --le)
                    economy_energy
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
        echo "enviando relatorio para seu email: $EMAIL"
        send_email "Relatorio de consumo de energia" "Segue em anexo o relatorio"  "energy_report.html"
}

#funcao p automatizar a economia de energia
economy_energy(){
        #tempo em segundos
        while true; do
                if  !  w | grep -q "usuario"; then
                        echo "Sistema inativo. Desligando tela..."
                        xset dpms force off
                        echo "Entrando em hibernação..."
                        systemctl hibernate
                fi
                sleep 6 #verificando a cada 60 segundos
        done
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
        echo "Resumo e uso do script com parâmetro -h"
        echo "Projeto de Monitoramento de Consumo de Energia"
        echo "Uso: $0 [-h] [-e] [--le]"
        echo "Opções:"
        echo "  -e    Monitorar consumo de energia"
        echo "  --le  Ativar modo economia de energia"
        echo "Equipe: [Railan Santana e Raquel Oliveira]"
}



main(){
        if [[ $OPTION_USER == "-h"  ]]; then
                help
                exit 1
        fi
        read -p "Digite seu email: " EMAIL
        cheks
        smtp_config
        process_perform
}

main
