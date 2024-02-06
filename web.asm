format ELF64 executable
sys_write equ 1
sys_exit equ 60
sys_socket equ 41
sys_bind equ 49
sys_listen equ 50
sys_close equ 3
sys_accept equ 43

AF_INET equ 2
SOCK_STREAM equ 1
INADDR_ANY equ 0
MAX_CON equ 2

STDOUT equ 1
STDERR equ 2
 
macro write fd, buffer, count{
	mov rax, sys_write
	mov rdi, fd
	mov rsi, buffer
	mov rdx, count
	syscall
}
macro socket domain, type, protocol{
	mov rax, sys_socket
	mov rdi, domain
	mov rsi, type
	mov rdx, protocol
	syscall
}
macro bind sockfd, addr, addrlen{
	mov rax, sys_bind
	mov rdi, sockfd
	mov rsi, addr
	mov rdx, addrlen
	syscall
}
macro listen sockfd, backlog{
	mov rax, sys_listen
	mov rdi, sockfd
	mov rsi, backlog
	syscall
}
macro accept sockfd, addr, addrlen{
	mov rax, sys_accept
	mov rdi, sockfd
	mov rsi, addr
	mov rdx, addrlen
	syscall
}
macro close fd{
	mov rax, sys_close
	mov rdi, fd
	syscall
}
macro exit code{
	mov rax, sys_exit
	mov rdi, code
	syscall
}
segment readable executable
entry main
main:
	write STDOUT, start, msg_len
	socket AF_INET, SOCK_STREAM, 0
	cmp rax, 0
	jl error
	mov qword [sockfd], rax
	
	mov word [servaddr.sin_family], AF_INET
	mov word [servaddr.sin_port], 14619
	mov dword [servaddr.sin_addr], INADDR_ANY
	bind [sockfd], servaddr.sin_family, servaddr_size
	cmp rax, 0
	jl error

	listen [sockfd], MAX_CON
	cmp rax, 0
	jl error

next_request:
	accept [sockfd], cliaddr.sin_family, cliaddr_size
	cmp rax, 0
	jl error
	
	mov qword [connfd], rax

	write [connfd], response, response_len
	jmp next_request

	close[connfd]
	close[sockfd]
	exit 0
error:
	write STDERR, err_msg, err_len
	close[connfd]
	close[sockfd]
	exit 1

segment readable writeable

struc addr_in {
	.sin_family dw 0
	.sin_port dw 0
	.sin_addr dd 0
	.sin_zero dq 0
}
sockfd dq -1
connfd dq -1
servaddr addr_in
servaddr_size = $ - servaddr.sin_family
cliaddr addr_in
cliaddr_size dd servaddr

response db "HTTP/1.1 200 OK", 13, 10
	 db "Content-Type: text/html; charset=utf-8", 13, 10
	 db "Connection: close", 13, 10
	 db 13, 10
	 db "<h1>Hello from flat assembler!</h1>", 10
response_len = $ - response
feedback db "Hello, from the vanilla arch's asm webserver", 10
feedback_len = $ - feedback

start db "Initalising the webserver", 10
msg_len = $ - start
err_msg db "Error Occured", 10
err_len = $ - err_msg
;;
;; Bytes informaiton: 
;; db - 1 bytes
;; dw - 2 bytes
;; dd - 4 bytes
;; dq - 8 bytes
;;
;; Struct for bind:
;; struct sockaddr_in{
;; 	sa_family_t sin_family;		16 bita
;;	in_port_t sin_port;		16 bits
;;	struct in_addr sin_addr;	32 bits
;;	uint8_t sin_zero[8];		64 bits
;;};
;;



