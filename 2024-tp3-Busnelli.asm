.data
slist:  .word 0
cclist: .word 0
wclist: .word 0
schedv: .space 32
menu:   .ascii "Colecciones de objetos categorizados\n"
        .ascii "====================================\n"
        .ascii "1-Nueva Categoria\n"
        .ascii "2-Siguiente categoria\n"
        .ascii "3-Categoria anterior\n"
        .ascii "4-Listar categorias\n"
        .ascii "5-Borrar categoria actual\n"
        .ascii "6-Anexar objeto a la categoria actual\n"
        .ascii "7-Listar objetos de la categoria\n"
        .ascii "8-Borrar objeto de la categoria\n"
        .ascii "0-Salir\n"
        .asciiz "Ingrese la opcion deseada: "
error:  .asciiz "Error: "
return: .asciiz "\n"
catName: .asciiz "\nIngrese el nombre de la categoria: "
selCat:  .asciiz "\nSe ha seleccionado la categoria: "
idObj:   .asciiz "\nIngrese el ID de objeto a eliminar: "
objName: .asciiz "\nIngrese el nombre del objeto: "
success: .asciiz "La operacion se realizo con exito\n\n"
hola:    .asciiz "\nhola\n"
.text
main:
    # Inicialización de las direcciones de las funciones en la tabla de saltos
    la $t0, schedv             # Cargar la dirección de schedv
    #la $t1, exit               # Cargar la dirección de exit
    #sw $t1, 0($t0)             # Guardar la dirección de exit en schedv[0]
    la $t1, newcategory        # Cargar la dirección de newcategory
    sw $t1, 0($t0)             # Guardar la dirección de newcategory en schedv[0]
    la $t1, nextcategory       # Cargar la dirección de nextcategory
    sw $t1, 4($t0)             # Guardar la dirección de nextcategory en schedv[4]
    la $t1, prevcategory       # Cargar la dirección de prevcategory
    sw $t1, 8($t0)             # Guardar la dirección de prevcategory en schedv[8]
    la $t1, listcategories     # Cargar la dirección de listcategories
    sw $t1, 12($t0)            # Guardar la dirección de listcategories en schedv[12]
    #la $t1, delcategory        # Cargar la dirección de delcategory
    #sw $t1, 16($t0)            # Guardar la dirección de delcategory en schedv[16]
    #la $t1, attachobject       # Cargar la dirección de attachobject
    #sw $t1, 20($t0)            # Guardar la dirección de attachobject en schedv[20]
    #la $t1, listobjects        # Cargar la dirección de listobjects
    #sw $t1, 24($t0)            # Guardar la dirección de listobjects en schedv[24]
    #la $t1, delobject          # Cargar la dirección de delobject
    #sw $t1, 28($t0)            # Guardar la dirección de delobject en schedv[28]
    
menu_loop:
    # Mostrar el menú
    li $v0, 4
    la $a0, menu
    syscall

    li $v0, 5              # Leer opción
    syscall
    move $t0, $v0          # Guardamos la opción seleccionada

    # Verificar si la opción es válida y llamar a la función correspondiente
    beq $t0, 0, exit            # Opción 0: Salir
    slti $t1, $t0, 9
    beq $t1, 0, error_option
    slt $t1, $0, $t0
    beq $t1, 0, error_option
    # Usar la opción seleccionada para obtener la dirección de la función de la tabla
    la $t1, schedv         # Cargar la dirección de la tabla schedv
    addi $t0, $t0, -1      # Resto 1 para luego multiplicar por 4
    sll $t2, $t0, 2        # Multiplicar la opción por 4 (para acceder a la tabla de funciones)
    add $t1, $t1, $t2      # Obtener la dirección de la función correspondiente
    lw $t1, 0($t1)         # Cargar la dirección de la función seleccionada
        #li $v0, 1#4
        #la $a0, 0($t2)#hola
        #syscall
        #j exit
    jalr $t1                 # Saltar a la función correspondiente y guardar pc en $ra para que pueda volver
    j menu_loop  # Si la opción es negativa, repetir el menú

# Función de error: Opción no válida
error_option:
    li $v0, 4
    la $a0, error
    syscall
    li $v0, 1
    li $a0, 101              # Error 101: Opción no válida
    syscall
    li $v0, 4
    la $a0, return            # Limpiar línea para la salida
    syscall
    j menu_loop  # Regresar al menú

# Funciones para asignar y "liberar" memoria
smalloc:
    lw $t0, slist
    beqz $t0, sbrk
    move $v0, $t0
    lw $t0, 12($t0)
    sw $t0, slist
    jr $ra
sbrk:
    li $a0, 16 # node size fixed 4 words
    li $v0, 9
    syscall # return node address in v0
    jr $ra
sfree:
    lw $t0, slist
    sw $t0, 12($a0)
    sw $a0, slist # $a0 node address in unused list
    jr $ra

# Funciones para crear y eliminar nodos
    # a0: list address
    # a1: NULL if category, node address if object
    # v0: node address added
addnode:
    addi $sp, $sp, -8
    sw $ra, 8($sp)
    sw $a0, 4($sp)
    jal smalloc
    sw $a1, 4($v0) # set node content
    sw $a2, 8($v0)
    lw $a0, 4($sp)
    lw $t0, ($a0) # first node address
    beqz $t0, addnode_empty_list
addnode_to_end:
    lw $t1, ($t0) # last node address
    # update prev and next pointers of new node
    sw $t1, 0($v0)
    sw $t0, 12($v0)
    # update prev and first node to new node
    sw $v0, 12($t1)
    sw $v0, 0($t0)
    j addnode_exit
addnode_empty_list:
    sw $v0, ($a0)
    sw $v0, 0($v0)
    sw $v0, 12($v0)
addnode_exit:
    lw $ra, 8($sp)
    addi $sp, $sp, 8
    jr $ra
    # a0: node address to delete
    # a1: list address where node is deleted
delnode:
    addi $sp, $sp, -8
    sw $ra, 8($sp)
    sw $a0, 4($sp)
    lw $a0, 8($a0) # get block address
    jal sfree # free block
    lw $a0, 4($sp) # restore argument a0
    lw $t0, 12($a0) # get address to next node of a0
node:
    beq $a0, $t0, delnode_point_self
    lw $t1, 0($a0) # get address to prev node
    sw $t1, 0($t0)
    sw $t0, 12($t1)
    lw $t1, 0($a1) # get address to first node
again:
    bne $a0, $t1, delnode_exit
    sw $t0, ($a1) # list point to next node
    j delnode_exit
delnode_point_self:
    sw $zero, ($a1) # only one node
delnode_exit:
    jal sfree
    lw $ra, 8($sp)
    addi $sp, $sp, 8
    jr $ra

# Funcion para obtener bloque de texto (un scanf de char*)
    # a0: msg to ask
    # v0: block address allocated with string
getblock:
    addi $sp, $sp, -4 # Reserva espacio en la pila
    sw $ra, 4($sp) # Guarda el valor de retorno
    li $v0, 4
    syscall
    jal smalloc
    move $a0, $v0
    li $a1, 16
    li $v0, 8
    syscall
    move $v0, $a0
    lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
    addi $sp, $sp, 4 # Liberar el espacio reservado en la pila.
    jr $ra # Regresar al lugar de donde se llamó la función


# Funciones de las opciones del menú:
newcategory:
    addiu $sp, $sp, -4
    sw $ra, 4($sp)
    la $a0, catName # input category name
    jal getblock
    move $a2, $v0 # $a2 = *char to category name
    la $a0, cclist # $a0 = list
    li $a1, 0 # $a1 = NULL
    jal addnode
    lw $t0, wclist
    bnez $t0, newcategory_end
    sw $v0, wclist # update working list if was NULL
newcategory_end:
    li $v0, 0 # return success
    lw $ra, 4($sp)
    addiu $sp, $sp, 4
    jr $ra


nextcategory:
    addi $sp, $sp, -4 # Reserva espacio en la pila
    sw $ra, 4($sp) # Guarda el valor de retorno
    lw $t1, wclist            # Cargar la categoría actual seleccionada
    beqz $t1, error_no_category  # Si no hay categoría seleccionada, error (201)
    lw $t2, 12($t1)           # Obtener la dirección del siguiente nodo
    beqz $t2, error_single_category  # Si hay solo una categoría, error (202)
    move $t1, $t2             # Cambiar a la siguiente categoría
    sw $t1, wclist            # Actualizar la categoría seleccionada
    # Se ha seleccionado la categoria:
    la $a0, selCat
    li $v0, 4
    syscall
    lw $a0, 8($t1)         # Cargar el puntero al nombre de la categoría (ubicado en el nodo)
    li $v0, 4              # syscall para imprimir cadena
    syscall
    
    lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
    addi $sp, $sp, 4 # Liberar el espacio reservado en la pila.
    li $v0, 0                 # Operación exitosa
    jr $ra
prevcategory:
    addi $sp, $sp, -4 # Reserva espacio en la pila
    sw $ra, 4($sp) # Guarda el valor de retorno
    lw $t1, wclist            # Cargar la categoría actual seleccionada
    beqz $t1, error_no_category  # Si no hay categoría seleccionada, error (201)
    lw $t2, 0($t1)            # Obtener la dirección del nodo anterior
    beqz $t2, error_single_category  # Si hay solo una categoría, error (202)
    move $t1, $t2             # Cambiar a la categoría anterior
    sw $t1, wclist            # Actualizar la categoría seleccionada
    # Se ha seleccionado la categoria:
    la $a0, selCat
    li $v0, 4
    syscall
    lw $a0, 8($t1)         # Cargar el puntero al nombre de la categoría (ubicado en el nodo)
    li $v0, 4              # syscall para imprimir cadena
    syscall
    lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
    addi $sp, $sp, 4 # Liberar el espacio reservado en la pila.
    li $v0, 0                 # Operación exitosa
    jr $ra
error_no_category:
    li $v0, 4
    la $a0, error
    syscall
    li $v0, 1
    li $a0, 201              # Error 201: No hay categoría seleccionada
    syscall
    la $a0, return            # Limpiar línea para la salida
    li $v0, 4
    syscall
    jr $ra
error_single_category:
    li $v0, 4
    la $a0, error
    syscall
    li $v0, 1
    li $a0, 202              # Error 202: Solo una categoría
    syscall
    la $a0, return            # Limpiar línea para la salida
    li $v0, 4
    syscall
    jr $ra


listcategories:
    #lw $t0, cclist            # Cargar la lista de categorías
    lw $t0, wclist            # Cargar la categoría actual seleccionada
    beqz $t0, error_empty      # Si la lista está vacía, mostrar error (301)
    # Imprimir todas las categorías
    la $a0, return            # Limpiar línea para la salida
    li $v0, 4
    syscall
    # Recorremos la lista de categorías e imprimimos
    loop:
        #move $a0, $t1         # Cargar el nombre de la categoría
        # Imprimir el símbolo ">" antes de la categoría seleccionada
        li $v0, 11              # syscall para imprimir caracter
        la $a0, 0x3E           # Mostrar símbolo ">" antes del nombre de la categoría seleccionada
        syscall
        lw $a0, 8($t0)         # Cargar el nombre de la categoría desde el nodo
        li $v0, 4
        syscall
        lw $t0, 12($t0)       # Ir al siguiente nodo
        lw $t3, wclist         # Cargar la categoría seleccionada en wclist
        beq $t0, $t3, end_list     # Si se llega al final de la lista, salir
        j loop
    end_list:
        li $v0, 0             # Operación exitosa
        jr $ra

error_empty:
    li $v0, 4
    la $a0, error
    syscall
    li $v0, 1
    li $a0, 301              # Error 301: No hay categorías
    syscall
    la $a0, return            # Limpiar línea para la salida
    li $v0, 4
    syscall
    jr $ra



exit:
    li $v0, 10                # Syscall para salir
    syscall
    jr $ra


