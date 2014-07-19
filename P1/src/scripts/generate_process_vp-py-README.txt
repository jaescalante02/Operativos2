Generate Process:
Genera un archivo con formato xml para ser utilizado en la simulacion de manejo de memoria a partir de los
parametros de entrada indicados utilizando la funcion random.

1. Utilizacion del programa:
   1.1 Correr el programa utilizando el comando:
       #> python generate_process_vp.py <numero_proc> <data_size> <tiempo_max> <instxpag>        

   1.2 Datos de Entrada:
       - numero_proc: Numero de procesos.
       - data_size: Numero maximo de bytes que puede ocupar cada proceso.
       - tiempo_max: Tick en el que llega el ultimo proceso.
       - instxpag: Numero de instrucciones que caben en una pagina. [Debe ser igual al numero de
         instrucciones por pagina especificado en la simulacion (Valor por defecto = 4)].

   1.3 Salida:
       Se genera el archivo process.xml que puede ser utilizado en la simulacion.
       

