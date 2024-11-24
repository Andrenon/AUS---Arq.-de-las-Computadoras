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
success: .asciiz "\nLa operacion se realizo con exito\n\n"
notFound: .asciiz "\nnotFound\n"

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
    la $t1, delcategory        # Cargar la dirección de delcategory
    sw $t1, 16($t0)            # Guardar la dirección de delcategory en schedv[16]
    la $t1, newobject          # Cargar la dirección de newobject
    sw $t1, 20($t0)            # Guardar la dirección de newobject en schedv[20]
    la $t1, listobjects        # Cargar la dirección de listobjects
    sw $t1, 24($t0)            # Guardar la dirección de listobjects en schedv[24]
    la $t1, delobject          # Cargar la dirección de delobject
    sw $t1, 28($t0)            # Guardar la dirección de delobject en schedv[28]
    
menu_loop:
    # Mostrar el menú
    la $a0, return            # Limpiar línea para la salida
    li $v0, 4
    syscall
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
# a1: NULL if category, node address (ID) if object
# a2: char* to category/object name
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
    sw $v0, 12($v0) # El nuevo nodo apunta a sí mismo como "prev" y "next"
addnode_exit:
    lw $ra, 8($sp)
    addi $sp, $sp, 8
    jr $ra
# a0: node address to delete
# a1: list address where node is deleted
delnode:
    addiu $sp, $sp, -8
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
            lw $a0, 4($sp)
    lw $ra, 8($sp)
    addiu $sp, $sp, 8
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
    move $a2, $v0 # $a2 = char* to category name
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
    addiu $sp, $sp, -4 # Reserva espacio en la pila
    sw $ra, 4($sp) # Guarda el valor de retorno
    lw $t1, wclist            # Cargar la categoría actual seleccionada
    beqz $t1, error_no_category  # Si no hay categoría seleccionada, error (201)
    lw $t2, 12($t1)           # Obtener la dirección del siguiente nodo
    beq $t2, $t1, error_single_category  # Si hay solo una categoría, error (202)
    move $t1, $t2             # Cambiar a la siguiente categoría
    sw $t1, wclist            # Actualizar la categoría seleccionada
    # Se ha seleccionado la categoria:
    la $a0, selCat
    li $v0, 4
    syscall
    lw $a0, 8($t1)         # Cargar el puntero al nombre de la categoría (ubicado en el nodo)
    li $v0, 4              # syscall para imprimir cadena
    syscall
    li $v0, 0                 # Operación exitosa
    lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
    addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
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
        lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
        addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
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
        lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
        addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
        jr $ra
        
prevcategory:
    addiu $sp, $sp, -4 # Reserva espacio en la pila
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
    li $v0, 0                 # Operación exitosa
    lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
    addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
    jr $ra


listcategories:
    addiu $sp, $sp, -4 # Reserva espacio en la pila
    sw $ra, 4($sp) # Guarda el valor de retorno
    lw $t0, cclist            # Cargar la lista de categorías
    beqz $t0, error_empty      # Si la lista está vacía, mostrar error (301)
    lw $t1, wclist            # Cargar la categoría actual seleccionada
    lw $t3, cclist            # Cargar la lista de categorías para recorrer
    # Imprimir todas las categorías
    la $a0, return            # Limpiar línea para la salida
    li $v0, 4
    syscall
    # Recorremos la lista de categorías e imprimimos
    loop_cat:
        beq $t3, $t1, sel_cat
        li $v0, 11              # syscall para imprimir caracter
        la $a0, 0x20           # Mostrar un espacio antes del nombre de la categoría seleccionada
        syscall
        j no_sel_cat
    sel_cat:
        li $v0, 11              # syscall para imprimir caracter
        la $a0, 0x3E           # Mostrar símbolo ">" antes del nombre de la categoría seleccionada
        syscall
    no_sel_cat:
        lw $a0, 8($t3)         # Cargar el nombre de la categoría desde el nodo
        li $v0, 4
        syscall
        lw $t3, 12($t3)       # Ir al siguiente nodo
        beq $t0, $t3, end_list     # Si se llega al final de la lista, salir
        j loop_cat
    end_list:
        li $v0, 0             # Operación exitosa
        lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
        addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
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
        lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
        addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
        jr $ra


delcategory:
    addiu $sp, $sp, -4 # Reserva espacio en la pila
    sw $ra, 4($sp) # Guarda el valor de retorno
    lw $t0, cclist            # Cargar la lista de categorías
    beqz $t0, error_empty_del      # Si la lista está vacía, mostrar error (401)
    # Verificar si la categoría tiene objetos
    lw $t1, wclist            # Cargar la categoría actual seleccionada
    lw $t1, 4($t1)            # Verificar si tiene objetos
    beqz $t1, delete_category
    # Primero eliminar los objetos asociados
    move $a0, $t1 # Copia el valor de $t2 a $t1
    jal delALLobjects             # Llamar a la función que elimina los objetos
    delete_category:
        lw $a0, wclist # $a0 = node address to delete (el nodo al que apunta wclist)
        la $a1, cclist # $a1 = list (la dirección de la lista para actualizar)
        jal delnode               # Llamar a la función que elimina el nodo
        lw $t0, cclist         # Cargamos el valor de cclist
        sw $t0, wclist         # Almacenamos el valor de cclist en wclist
        li $v0, 0                 # Operación exitosa
        lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
        addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
        jr $ra
    error_empty_del:
        li $v0, 4
        la $a0, error
        syscall
        li $v0, 1
        li $a0, 401              # Error 401: No hay categorías
        syscall
        la $a0, return           # Limpiar línea para la salida
        li $v0, 4
        syscall
        lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
        addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
        jr $ra
    delALLobjects: # $a0: Objects list address
        addiu $sp, $sp, -16
        sw $ra, 16($sp)
        sw $a0, 12($sp)
        sw $a1, 8($sp)
        sw $a2, 4($sp)
        move $a1, $a0 # Save 1° obj # Copia el valor de $t2 a $t1
        la $a2, ($a0)
        lw $a0, 12($a0) # Ir al siguiente nodo
        delobjects_loop:
            # $a0 = node address to delete (el nodo a borrar)
            # $a1 = list (la dirección de la lista para actualizar)
            lw $a3, 12($a0)       # Ir al siguiente nodo
            jal delnode               # Llamar a la función que elimina el nodo
            move $a0, $a3 # restauro siguiente nodo
            beq $a0, $a2, exit_delobjects     # Si se llega al final de la lista, salir
            j delobjects_loop
        exit_delobjects:
        jal delnode               # Llamar a la función que elimina el nodo
        lw $a2, 4($sp)
        lw $a1, 8($sp)
        lw $a0, 12($sp)
        lw $ra, 16($sp)
        addiu $sp, $sp, 16
        jr $ra


newobject:
    addiu $sp, $sp, -4 # Reserva espacio en la pila
    sw $ra, 4($sp) # Guarda el valor de retorno
    lw $t0, cclist           # Cargar la lista de categorías
    beqz $t0, error_empty_new_obj  # Si no hay categoría seleccionada, error
    la $a0, objName # input object name
    jal getblock
    move $a2, $v0 # $a2 = char* to category name
    lw $t0, wclist            # Cargar la categoría actual seleccionada
    lw $a0, 4($t0) # Dirección 1° objeto
    jal get_id_obj
    move $a1, $v0 # $$a1 = ID obj node
        #lw $t0, wclist            # Cargar la categoría actual seleccionada
        la $a0, 4($t0) # Dirección puntero a 1° objeto
    jal addnode
        bnez $a0, obj_exist # Si es el 1° objeto actualizar puntero
        lw $t0, wclist            
        sw $v0, 4($t0) # update obj pointer
    obj_exist:
    li $v0, 4                # Imprimir mensaje de éxito
    la $a0, success
    syscall
    li $v0, 0                 # Operación exitosa
    lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
    addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
    jr $ra
    error_empty_new_obj:
        # Si no hay categoría seleccionada
        li $v0, 4
        la $a0, error
        syscall
        li $v0, 1
        li $a0, 501              # Error 501: No hay categorías
        syscall
        la $a0, return           # Limpiar línea para la salida
        li $v0, 4
        syscall
        lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
        addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
        jr $ra
    get_id_obj: # Dir 1° objeto
        addiu $sp, $sp, -16
        sw $ra, 16($sp)
        sw $a0, 12($sp)
        sw $a1, 8($sp)
        sw $a2, 4($sp)
        li $v0, 1 # Inicio contador, ya se que no está vacío
        beqz $a0, exit_id # único nodo
        move $a1, $a0 # guardo puntero a 1° objeto
        loop_get_id:
            lw $a2, 4($a0) # Cargo el dato del objeto
            lw $a0, 12($a0) # Apunto al siguiente
            beq $a2, $v0, add_get_id
            beq $a0, $a1, exit_id     # Si se llega al final de la lista, salir
            j loop_get_id
            add_get_id:
            addi $v0, $v0, 1
            j loop_get_id
        exit_id:
            lw $a2, 4($sp)
            lw $a1, 8($sp)
            lw $a0, 12($sp)
            lw $ra, 16($sp)
            addiu $sp, $sp, 16
            jr $ra


listobjects:
    addiu $sp, $sp, -4 # Reserva espacio en la pila
    sw $ra, 4($sp) # Guarda el valor de retorno
        la $a0, return           # Limpiar línea para la salida
        li $v0, 4
        syscall
    lw $t0, wclist            # Cargar la categoría actual seleccionada
    beqz $t0, error_empty_cat_list_obj      # Si no hay categoría seleccionada, error
    lw $t1, 4($t0)            # Cargar el primer objeto
    beqz $t1, error_empty_obj      # Si no hay objetos, error
    # Imprimir todas las categorías
    la $a0, return            # Limpiar línea para la salida
    li $v0, 4
    syscall
    # Imprime categoría actual
    li $v0, 11              # syscall para imprimir caracter
    la $a0, 0x3E           # Mostrar símbolo ">" antes del nombre de la categoría seleccionada
    syscall
    lw $a0, 8($t0)         # Cargar el nombre de la categoría desde el nodo
    li $v0, 4
    syscall
    # Recorremos la lista de objetos e imprimimos
    move $t2, $t1 # Guardo 1° obj # Copia el valor de $t1 a $t2
    loop_obj:
        li $v0, 11              # syscall para imprimir caracter
        la $a0, 0x09           # Mostrar un tabulador antes del nombre del objeto
        syscall
        lw $a0, 8($t1)         # Cargar el nombre del objeto desde el nodo
        li $v0, 4
        syscall
        lw $t1, 12($t1)       # Ir al siguiente nodo
        beq $t1, $t2, end_list_obj     # Si se llega al final de la lista, salir
        j loop_obj
    end_list_obj:
        la $a0, return           # Limpiar línea para la salida
        li $v0, 4
        syscall
        li $v0, 0             # Operación exitosa
        lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
        addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
        jr $ra
    error_empty_cat_list_obj:
        # Si no hay categoría seleccionada
        li $v0, 4
        la $a0, error
        syscall
        li $v0, 1
        li $a0, 601              # Error 601: No hay categorías
        syscall
        lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
        addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
        jr $ra
    error_empty_obj:
        # Si no hay objetos en la categoría seleccionada
        li $v0, 4
        la $a0, error
        syscall
        li $v0, 1
        li $a0, 602              # Error 602: No hay objetos
        syscall
        lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
        addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
        jr $ra



delobject:
    addiu $sp, $sp, -4 # Reserva espacio en la pila
    sw $ra, 4($sp) # Guarda el valor de retorno
        la $a0, return           # Limpiar línea para la salida
        li $v0, 4
        syscall
    lw $t0, wclist           # Cargar la lista de categorías
    beqz $t0, error_empty_del_obj  # Si no hay categoría seleccionada, error
    lw $t1, 4($t0)
    beqz $t1, error_del_no_obj
    la $a0, idObj # input id object
    li $v0, 4
    syscall
    li $v0, 5              # Leer opción
    syscall
    move $a2, $v0          # Guardamos la opción seleccionada
    #jal getblock
         lw $t0, wclist           # Cargar la lista de categorías VER PORQUE $t0 APUNTA A 0
    lw $a0, 4($t0) # 1° objeto
    move $a1, $a2 # objet id
    lw $a3, 12($a0) # Guardo dirección del siguiente objeto por si se borra el 1°
    jal id_delobj #Return 0 / Address of the deleted node
    #move $a1, $v0 # $$a1 = true/false ID obj node
    beqz $v0, not_found
         lw $t0, wclist           # Cargar la lista de categorías VER PORQUE $t0 APUNTA A 0
    lw $a1, 4($t0) # Dirección del 1° obj
    bne $a1, $v0, exit_delobject
    bne $a3, $v0, obj_list_pointer_change
        sw $zero, 4($t0) # Se borró el último/único objeto
        j exit_delobject
    obj_list_pointer_change:
    sw $a3, 4($t0) # update obj pointer
    exit_delobject:
    li $v0, 4                # Imprimir mensaje de éxito
    la $a0, success
    syscall
    li $v0, 0                 # Operación exitosa
    lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
    addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
    jr $ra
    id_delobj: # a0: list obj address, $a1: id_del                #,    $a2: cat address
        addiu $sp, $sp, -20
        sw $ra, 20($sp)
        sw $a0, 16($sp)
        sw $a1, 12($sp)
        sw $a2, 8($sp)
        sw $a3, 4($sp)
        li $v0, 0             # Return false
        move $a3, $a0 # Save 1° obj # Copia el valor de $a0 a $a3
        id_delobj_loop:
            lw $a2, 4($a0) # obj_id 
            beq $a2, $a1, end_list_obj_s     # Si se llega encuentra id, salir y return true
            lw $a0, 12($a0)       # Ir al siguiente nodo
            beq $a0, $a3, end_id_delobj     # Si se llega al final de la lista, salir
            j id_delobj_loop
        end_list_obj_s:
            # $a0 = node address to delete (el nodo a borrar)
            la $a1, 0($a3) # $a1 = list (la dirección de la lista para actualizar)
            jal delnode               # Llamar a la función que elimina el nodo
            la $v0, ($a0)             # Return true, dirección del nodo borrado
        end_id_delobj:
            lw $a3, 4($sp)
            lw $a2, 8($sp)
            lw $a1, 12($sp)
            lw $a0, 16($sp)
            lw $ra, 20($sp)
            addiu $sp, $sp, 20
            jr $ra
    not_found:
        li $v0, 4
        la $a0, error
        syscall
        li $v0, 4
        la $a0, notFound              # Error: notFound
        syscall
        lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
        addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
        jr $ra
    error_empty_del_obj:
        # Si no hay objetos en la categoría seleccionada
        li $v0, 4
        la $a0, error
        syscall
        li $v0, 1
        li $a0, 701              # Error 701: No hay categorías
        syscall
        lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
        addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
        jr $ra
    error_del_no_obj:
        li $v0, 4
        la $a0, error
        syscall
        li $v0, 1
        li $a0, 702              # Error 702: No existen objetos
        syscall
        lw $ra, 4($sp) # Recuperar la dirección de retorno ($ra) desde la pila.
        addiu $sp, $sp, 4 # Liberar el espacio reservado en la pila.
        jr $ra



exit:
    li $v0, 10                # Syscall para salir
    syscall
    jr $ra
