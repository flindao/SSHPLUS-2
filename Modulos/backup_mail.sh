#!/bin/bash
# script de backup com envio autom�tico de e-mails antes e ap�s a
# conclus�o do mesmo:.
# Autor: Igor Rocha
# Data: 20/05/2012

# Vari�veis auxiliares:.(Utilizadas no decorrer do script)
# No exemplo esta sendo utilizado o /etc, porem fica a crit�rio do 
# Admin/usu�rio escolher qual o diret�rio a ser backupeado:.
NOME_DIRETORIO_DESTINO="/etc/" 
export NOME_DIRETORIO_DESTINO

# Nome do diret�rio para onde o backup ser� movido, ap�s sua 
# conclus�o: (N�o esque�a de verificar as permiss�es do diret�rio
# onde o backup ser� movido)
NOME_DIRETORIO_MOV="/mnt/backup"

# Formata��o da Data:Neste caso a formata��o fica da seguinte forma:
# Ex:. 20/05/2012 para outras formas verifique o manual do comando 
# date com <man date>
DATA_BACKUP=$(date "+%d/%m/%y")

# Hor�rio da realiza��o do Backup:.
HORARIO_BACKUP=$(date|awk '{print $4}')

# Nome dos Arquivos de Log
LOG_ERRO_BACKUP="backup_info.log"

# A partir daqui s�o utilizadas vari�veis para a autentica��o do email
# que ser� enviado ap�s o termino do backup, ou em caso de alguma falha
# no decorrer do backup ou ap�s a sua conclus�o.
# O software utilizado para enviar os e-mails, � o SendEmail,(sendemail)
# h� uma fun��o que verifica se o mesmo ja est� instalado no servidor
# isto em distros derivadas do Debian, (.deb), porem � poss�vel alterar
# o script para rodar em outras distribui��es, para isso verifique o 
# gerenciador de pacotes que roda em sua distro e altere a fun��o
# verifica_pckg_email() de acordo com a sua distro.

# Nome do E-mail do remetente:
NOME_EMAIL_DEST="seu-email@dominio.com.br"


# E-mail do Destinat�rio:
EMAIL_DESTINATARIO="e-mail-de-quem-ira-receberMSG@dominio.com.br"

# Assunto do E-mail: em branco no inicio pois o script que ira definir
# no decorrer da execu��o:
EMAIL_ASSUNTO=""

# Corpo da mensagem, tamb�m em branco.
EMAIL_MENSAGEM=""

# Endere�o do Servidor SMTP que ir� ser autenticado(neste caso o yahoo)
# Para descobrir o seu servidor SMTP, entre nas configura��es do seu e-mail
# e procure por redirecionamento de e-mail, a configura��o de cada um � diferente
# aqui tem alguns: 
# http://pt.kioskea.net/faq/844-enderecos-dos-servidores-pop-e-smtp-dos-principais-fai
# O 25 indica a porta Default onde o Servi�o do SMTP roda, por�m nem todos rodam 
# nesta mesma porta, como no caso do gmail que roda na porta 995, ent�o
# altere a porta de acordo com a sua necessidade.
EMAIL_SMTP_ADDR="smtp.mail.yahoo.com.br:25"

# Nome do Usu�rio do ser provedor de e-mails:
EMAIL_USER="seu-usuario@gmail.com"

# Senha do Usu�rio:
EMAIL_SENHA="sua-senha"

# FIM DAS VAR�AVEIS #
#########################################################################################

# FUN��ES UTILIZADAS NO SCRIPT:.
# Verifica a conex�o com a internet:.
# � necess�rio verificar no seu roteador/gateway se o ICMP n�o est� bloqueado caso contr�rio
# o script n�o funcionara.
verifica_conexao()
{
	# teste a conex�o com a internet, enviando 3 pings so google: 
	echo -e "\ntVerificando a conex�o com a internet.">>$LOG_ERRO_BACKUP
	ping -c 3 www.google.com >/dev/null

	if [ $? != 0 ];then
		echo -e " $(date) ERRO: N�o a conex�o com a internet, ou h� algum firewall/roteador
		      bloqueando o protocolo ICMP, impossibilitando o teste de conex�o com a internet
		      backup abortado em $DATA_BACKUP, verifique o ocorrido e rode o backup novamente.">>$LOG_ERRO_BACKUP
		      exit 1
	else
		echo -e "$(date) INFO: Teste de conex�o com a internet realizado com sucesso na data $DATA_BACKUP\n
		      Iniciando backup....">>$LOG_ERRO_BACKUP
		fi

}


# Verifica se o pacote sendemail j� esta instalado, se n�o estiver o mesmo aborta o script:.
# em distros derivadas do Debian, caso voc� queira desativar esta fun��o para rodar o script
# em outra distro, basta comentar a linha mais abaixo onde ocorre a chamada da fun��o.
# PS:. Fora colocado um coment�rio acima da linha que deve ser comentada.

verifica_pckg_email()
{
	# Usando o dpkg(Debian package) a fun��o faz uma busca, na lista de pacotes instalados
	# caso o mesmo n�o esteja o script encerra por aqui.
	echo -e "\ntVerificando se o pacote sendemail est� instalado">>$LOG_ERRO_BACKUP
	dpkg --list|grep sendemail>/dev/null

	if [ $? != 0 ];then
		echo -e " $(date) ATEN��O: O pacote sendemail n�o est� instalado, por favor, realize a instala��o
			do mesmo, e rode o script novamente, o problema pode ser resolvido utilizado o  
			apt-get(apt-get-install sendemail).\n
			O script foi abortado..\n">>$LOG_ERRO_BACKUP
			exit 1
	else
		echo -e "$(date) O Pacote sendemail encontra-se instalado no servidor $(hostname)...
			\nBackup em andamento..." >>$LOG_ERRO_BACKUP
	fi

}



# Fun��o utilizada que envia um e-mail informando o usu�rio/admin de que o backup est� iniciando.
backup_msg_inicio()
{
	# Ajustando os valores da vari�veis:.
	EMAIL_ASSUNTO="Backup do Filesystem $NOME_DIRETORIO_DESTINO iniciado, rodando no servidor $(hostname)"
	EMAIL_MENSAGEM="############### BACKUP INICIALIZADO ####################"
	
	echo -e "\nEnviado e-mail de testes.">>$LOG_ERRO_BACKUP
	# Realizado o envio da mensagem com o sendemail:
	sendemail -f $NOME_EMAIL_DEST -t $EMAIL_DESTINATARIO  -u $EMAIL_ASSUNTO  -m $EMAIL_MENSAGEM -s $EMAIL_SMTP_ADDR  -xu $EMAIL_USER  -xp $EMAIL_SENHA>info_smtp.tmp
	if [ $? != 0 ];then
		echo -e "$(date) ERRO: Problema ao enviar e-mail, abaixo verifique a saida do sendemail para constatar
			  	 o problema, e ent�o rode o backup novamente:	
				 $(cat info_smtp.tmp).\n">>$LOG_ERRO_BACKUP
				 rm info_smtp.tmp
				 exit 1
	else
		echo -e "$(date) E-mail de testes enviado com sucesso, backup em andamento..">>$LOG_ERRO_BACKUP
	fi

}

# Fun��es do backup propiamente dito (.tar.gz)
# Tamanho do backup
backup_size(){  du -hs "$1" | cut -f1; }

# Verificando enquanto a c�pia do backup esta rodando
backup_rodando()
{
	
	ps $1 | grep $1 >/dev/null

}


# Auxiliar
AUX=$(echo $NOME_DIRETORIO_DESTINO| cut -d"/" -f2)

# fun��o que inicia o backup
backup_start()
{
	# mensagem no arquivo de log
	echo -e "\n######### INICIANDO BACKUP ##########.">>$LOG_ERRO_BACKUP

	# inico do Backu
	/usr/bin/time -p -o info_time tar -cvzf ${AUX}`date +%Y_%m_%d__%H_%M_%S`.tar.gz "$1"

}


envia_msg_backup()
{
	# ap�s a realiza��o do backup envia uma mensagem informando a realiza��o correta
	# do backup com o nome do arquivo gerado.
	NOME_ARQUIVO=$(ls -la *.tar.gz|cut -d" " -f8)

	# Ajustando o valor das var�aveis:
	EMAIL_ASSUNTO="Backup do FileSystem $NOME_DIRETORIO_DESTINO realizado com sucesso na data $(date)"
	EMAIL_MENSAGEM="Atencao o backup de $NOME_DIRETORIO_DESTINO foi realizado com sucesso na data $(date).\n
			\n
			#############################################################################
			\n
			\nInformacoes:\n
			\nNome do Diretorio a ser backupeado: $NOME_DIRETORIO_DESTINO.\n
			\nNome do Arquivo final: $NOME_ARQUIVO.\n
			\nTempo de Execucao do backup:\n
			$(cat info_time)\n
			\nNome do arquivo de Log: $LOG_ERRO_BACKUP\n
			\nData de criacao do Backup: $DATA_BACKUP\n
			\nHorario de Criacao do Backup: $HORARIO_BACKUP\n
			\n
			#############################################################################
			\n
			"
			rm info_time

        # Realizado o envio da mensagem com o sendemail:
        sendemail -f $NOME_EMAIL_DEST -t $EMAIL_DESTINATARIO  -u $EMAIL_ASSUNTO  -m $EMAIL_MENSAGEM -s $EMAIL_SMTP_ADDR  -xu $EMAIL_USER  -xp $EMAIL_SENHA>>$LOG_ERRO_BACKUP
        if [ $? != 0 ];then
                echo -e "$(date) ERRO: Problema ao enviar e-mail, abaixo verifique a saida do sendemail para constatar
                                 o problema, e ent�o rode o backup novamente:   
                                 $(cat info_smtp.tmp).\n">>$LOG_ERRO_BACKUP
                                 rm info_smtp.tmp
                                 exit 1
        else
                echo -e "$(date)  backup finalizado com sucesso\n..">>$LOG_ERRO_BACKUP
        fi




}

# Fun��o que move o backup realizado para o diret�rio informado no inicio do script:
move_backup()
{
	echo "$(date) INFO: Movendo o arquivo $NOME_ARQUIVO para o diret�rio $NOME_DIRETORIO_MOV.">>$LOG_ERRO_BACKUP
	/usr/bin/time -p -o info_mv mv $NOME_ARQUIVO $NOME_DIRETORIO_MOV
	if [ $? != 0 ];then
		      # mensagem de sucesso
		      INFO_ERRO="Ante��o ouve um erro ao mover o arquivo $NOME_ARQUIVO para o diret�rio $NOME_DIRETORIO_MOV,
		      verifique o ocorrido, e tente move-lo manualmente."

                      sendemail -f $NOME_EMAIL_DEST -t $EMAIL_DESTINATARIO  -u "ERRO na Aloca��o do Backup $NOME_ARQUIVO"  -m $INFO_ERRO -s $EMAIL_SMTP_ADDR  -xu $EMAIL_USER  -xp $EMAIL_SENHA>>$LOG_ERRO_BACKUP

		      echo $INFO_ERRO>>$LOG_ERRO_BACKUP

		      rm info_mv
		

		
	else
		     # mensagem de erro
                     INFO_OK="O arquivo $NOME_ARQUIVO foi movido com sucesso para o diret�rio $NOME_DIRETORIO_MOV,
                     na data $(date) com o tempo de $(cat info_mv)"
                    sendemail -f $NOME_EMAIL_DEST -t $EMAIL_DESTINATARIO  -u "Aloca��o do Backup $NOME_ARQUIVO realizado com sucesso"  -m $INFO_OK -s $EMAIL_SMTP_ADDR  -xu $EMAIL_USER  -xp $EMAIL_SENHA

		    echo $INFO_OK>>$LOG_ERRO_BACKUP
		    
   		    rm info_mv
	fi



}

# Disparando as fun��es do script
verifica_conexao
# Para rodar em outra distro basta comentar (Colocar um # na frente) da linha abaixo. onde se econtra verifica_pckg_email.
verifica_pckg_email	
backup_msg_inicio
backup_start $NOME_DIRETORIO_DESTINO
envia_msg_backup
move_backup

# Fim #####################################################################




