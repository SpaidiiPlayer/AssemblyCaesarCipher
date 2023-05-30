;Autor: Matheus Vinagre
;CIFRA DE CESAR EM ASSEMBLY MASM32

.686
.model flat, stdcall
option casemap :none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
include \masm32\include\msvcrt.inc

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\msvcrt.lib
include \masm32\macros\macros.asm

.data
    Mensagem0 db "Digite o nome do arquivo a ser lido: ", 0                                                 ;      
    Mensagem1 db "Digite o nome do arquivo a ser escrito: ", 0                                              ; Strings usadas para o 
    Mensagem2 db "Digite a chave da cifra: ", 0                                                             ; funcionamento do MENU
    Mensagem db "Escolha uma opcao:",10, "1-Criptografar",10,"2-Descriptografar",10,"3-Encerrar",10, 0      ;                  
    Escolha db 4 dup(0)                  ;String onde será recebida um input
    CharEscolha db ?                     ;Valor em BYTE da escolha
    arquivoSaida db 50 dup(0)                             ;String onde será armazenada o nome do arquivo de entrada 
    arquivoEntrada db 50 dup(0)                           ;String onde será armazenada o nome do arquivo de saída
    chave db 4 dup(0)                    ;String que receberá o input do usuário                             
    handleEntrada dd 0          ; Armazena o handle de entrada
    handleSaida dd 0            ; Armazena o handle de saída
    console_count dd 0          ; Contador de caracteres lidos no console
    buffer       db 512 dup(0)  ; buffer que lê e escreve os dados
    bytesRead    dd ?           ; Quantidade de bytes lidos ao ler o arquivo
    bytesWritten dd ?           ; Quantidade de bytes escritos no arquivo
    ponteiro     dd ?           ; Ponteiro que armazenará o endereço do arquivo que ESCREVE


.code

start:
    invoke GetStdHandle, STD_INPUT_HANDLE
    mov handleEntrada, eax
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov handleSaida, eax   
 inicio:                                             
    invoke WriteConsole, handleSaida, addr Mensagem, sizeof Mensagem , addr console_count, NULL
    invoke ReadConsole, handleEntrada, addr Escolha, sizeof Escolha, addr console_count, NULL   ;O usuario faz um input armazenado em Escolha


    mov esi, OFFSET Escolha                           ; Nesse trecho após ser inserido a Escolha, os valores estão como BYTE  
    mov al, [esi]                                     ; Então os caracteres '1','2','3' valem '49','50','51', dessa forma apenas
    sub al, 48                                        ; subtraio 48 do valor do BYTE, para ter o valor 1,2 ou 3 no BYTE
    cmp al, 3                                         ; Caso o valor seja 3, ele vai para o fim da execução
    je fim_MAIN
    mov CharEscolha, al                               ;Armazeno o valor do BYTE escolha (para futuramente dar push para usar como parametro)

    invoke WriteConsole, handleSaida, addr Mensagem2, sizeof Mensagem2, addr console_count, NULL    
    invoke ReadConsole, handleEntrada, addr chave, sizeof chave, addr console_count, NULL        ;O usuário faz o input amarzenado em Chave

    
        mov esi, OFFSET chave
        mov al, [esi]                           ;Nesse trecho é visto o primeiro caractere
        sub al, 48                              ;E subtraido por 48 (pelo mesmo motivo que foi usado na variavel Escolha
        mov dl, [esi+1]                         ;Caso o segundo Byte da String Chave seja um "carriage return" (Envio do usuário)
        cmp dl, 13                              ;significa que a chave não possui dezenas e então o valor do 
        je fimjunta                             ;primeiro byte subtraido por 48 é o valor da chave
            cmp al, 1                               ;Caso exista valor util no segundo Byte significa que o primeiro byte armazena a dezena
            je vira10                               ;E então se há 1 no primeiro byte significa que tem o valor de 10
            jg vira20                               ;Caso tenha algum outro valor fora 1 será tratado como 20 (limite definido para chave)

            vira10:
                mov al, 10                          ;Transforma o 1 em 10 
                jmp junta
            vira20:
                mov al, 20                          ;Transforma em 20
       junta:
        sub dl, 48                              ;Diminui o valor da unidado por 48 para ter seu valor desejado
        add al, dl                              ;Soma a dezena com a unidade

    fimjunta:
    mov [esi], al                               ;Armazena o valor util na primeira posicao da string chave

    invoke WriteConsole, handleSaida, addr Mensagem0, sizeof Mensagem0 , addr console_count, NULL               ;
                                                                                                                ; Pede ao usuário para digitar
    invoke ReadConsole, handleEntrada, addr arquivoEntrada, sizeof arquivoEntrada, addr console_count, NULL     ; os nomes de 2 arquivos um para
                                                                                                                ; ser lido e o outro escrito
    invoke WriteConsole, handleSaida, addr Mensagem1, sizeof Mensagem1 , addr console_count, NULL               ; (caso o arquivo para ser escrito
                                                                                                                ; nao exista, é criado um novo)
    invoke ReadConsole, handleEntrada, addr arquivoSaida, sizeof arquivoSaida, addr console_count, NULL         ;

    
    mov esi, OFFSET arquivoEntrada                  ;Passa o endereço do nome do arquivo de entrada para ser ajustado
    xor ecx, ecx    

        ajeitaString:                               ;ajeitaString ajusta a string que armazena o nome do arquivo de entrada
                                                    ;é necessário remover 'carriage return' do nome dos arquivos
            mov al, [esi]    
            inc esi
            cmp al, 13                              ;enquanto não encontrar o carriege return continua percorrendo a string
            jne ajeitaString
     
        dec esi                                     
        xor al, al                                  ;quando achar encontrar setar como 0 (\0 em ascii, que é significa o fim da string)
        mov [esi], al
        
        mov esi, OFFSET arquivoSaida                ;Passa o endereço do nome do arquivo de saida para ser ajustado
        inc ecx
        cmp ecx, 2                                  ;Como vai ser ajustado 2 strings, quando o contador chegar a 2
        jne ajeitaString                            ;significa que as duas strings foram corrigidas para o uso



    invoke CreateFile, ADDR arquivoEntrada, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL   ;Abre o arquivo para ler
    mov esi, eax  ;Armazena o endereço da entrada

    invoke CreateFile, ADDR arquivoSaida, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL    ;Abre/Cria o arquivo para escrever
    mov ponteiro, eax   ;Armazena o endereço da saida
    
    transferedados:
        invoke ReadFile, esi, addr buffer, sizeof buffer, addr bytesRead, 0             ;Ler o arquivo
       
        mov edi, OFFSET chave                                                           
        push [edi]                      ;Empilha a chave (1byte)
        
        mov eax, bytesRead      
        push eax                        ;Empilha a quantidade de caracteres lidos (4bytes)

        mov edi, OFFSET buffer
        push edi                        ;Empilha o endereço do BUFFER (4bytes)


    mov al, CharEscolha
    cmp al, 2               ;Caso a escolha tenha sido 2
    je descript             ;Ele pula para o descriptar
    
    call codificar          ;Chama funcao codificar
    jmp escreve    
    
    descript:    

    call decodificar        ;Chama funcao descodificar

    escreve:
    mov edi, ponteiro       
    invoke WriteFile, edi, addr buffer, bytesRead, addr bytesWritten, 0     ;Escreve o buffer no arquivo de saída
               

        mov eax, bytesWritten                           
        cmp eax, 512                                ;caso ainda tenha mais algo a ser escrito ele volta, para ler e escrever o que falta.
        je transferedados                   
        
        invoke CloseHandle, esi                     ;caso tenha sido escrito tudo, ele fecha os arquivos.
        invoke CloseHandle, edi
        jmp inicio
    fim_MAIN:


    invoke ExitProcess, 0                           ;Fim da MAIN




;FUNCAO CODIFICAR
;
;A funcao executa a cifra de Cesar no buffer, mudando o valor caracteres de acordo com a chave passada.
;
  codificar:    
        push ebp                    ;Empilha o valor de EBP
        mov ebp, esp                ;EBP passa a apontar para o fim da pilha

   mov dl, BYTE PTR[ebp+16]         ;CHAVE

   mov ecx, DWORD PTR[ebp+12]       ;TAMANHO 
    
   mov edi, DWORD PTR[ebp+8]        ;BUFFER
   
    
             soma:
                cmp ecx, 0                  ;Enquanto o contador não for zero, ele executa
                je fim_som                  ;as instruções abaixo
                    
                dec ecx                     ; Nesse trecho
                mov al, [edi]               ; Cada caractere do buffer é movido para o registrador para ser
                add al, dl                  ; somado com o valor da chave
                mov [edi], al               ; E devolvido ao buffer com a troca realizada
                inc edi                     ; É incrementado para apontar para apontar para proximo caractere do buffer
                jmp soma                    ; volta para o soma

            fim_som:
            
    pop ebp
    ret


;FUNCAO DECODIFICAR
;
;A funcao executa a cifra de Cesar 'ao contrário' no buffer, mudando o valor caracteres de acordo com a chave passada.
;A função faz exatamente quase a mesma coisa que a funcao codificar, com excessão de que ao invés do buffer
;ser somado pela chave, ele será subtraido.
;
   decodificar:    
        push ebp
        mov ebp, esp

   mov dl, BYTE PTR[ebp+16]         ;CHAVE
   
   mov ecx, DWORD PTR[ebp+12]       ;TAMANHO 
    
   mov edi, DWORD PTR[ebp+8]        ;BUFFER
   
    
             subtracao:
                cmp ecx, 0
                je fim_sub
                    
                dec ecx
                mov al, [edi]
                sub al, dl                  ;Aqui sendo subtraido
                mov [edi], al
                inc edi
                jmp subtracao

            fim_sub:
            
    pop ebp
    ret

end start
