# **Vankora DCOP Protocol: Stablecoin del Peso Colombiano**

Vankora DCOP es un protocolo de deuda colateralizada que permite a los usuarios depositar **USDC** como colateral para emitir **DCOP**, una stablecoin sintética vinculada 1:1 al **Peso Colombiano (COP)**.

El objetivo principal de Vankora es ofrecer acceso a **liquidez en pesos colombianos on-chain**, sin que los usuarios tengan que desprenderse de su exposición al dólar. De esta forma, los usuarios pueden obtener DCOP para gastos, pagos o cobertura frente a la inflación local, mientras mantienen USDC como reserva de valor a largo plazo.

DCOP no está respaldada por pesos en cuentas bancarias, sino por un sistema de **colateralización y reglas económicas** que buscan mantener su paridad con el COP de manera descentralizada y transparente.

## **Mecanismos de Estabilidad del Peg**

El protocolo mantiene la paridad 1:1 entre DCOP y COP mediante una combinación de incentivos económicos y mecanismos de seguridad:

### **1. Sobre-colateralización**

Cada DCOP emitido está respaldado por una cantidad de USDC cuyo valor excede el de la deuda emitida.
Esto garantiza que el sistema tenga un **colchón de seguridad** frente a la volatilidad del mercado y reduce el riesgo sistémico ante caídas abruptas del colateral.

### **2. Redimibilidad (Hard Peg)**

DCOP puede ser redimido directamente contra el protocolo por USDC a **valor nominal** (Precio de oraculo), menos una **tarifa de redención**.
Este mecanismo se activa especialmente cuando el precio de mercado de DCOP cae por debajo de su paridad con el COP (depeg), creando una oportunidad de arbitraje que empuja el precio de vuelta al peg.

### **3. Control de Emisión**

Vankora no utiliza tasas de interés variables sobre la deuda.
En su lugar, la emisión de DCOP está sujeta a una **tarifa de emisión fija**, pagada al momento de crear deuda. Esto ofrece:

* Previsibilidad de costos para el usuario
* Simplicidad en el modelo económico
* Eliminación del riesgo de “deuda creciente” por intereses acumulados

---

# **Redenciones: Mecanismo de Peg de Última Instancia**

Las redenciones constituyen el **mecanismo de última instancia** para la estabilidad del sistema y establecen un **suelo duro (hard floor)** para el precio del DCOP.

Cualquier poseedor de DCOP puede canjear sus tokens directamente contra el protocolo por USDC a valor nominal. Durante este proceso:

* El DCOP redimido se quema
* La deuda se cancela comenzando por las posiciones más riesgosas
* El colateral correspondiente es transferido al redentor

Este diseño asegura que, incluso en escenarios de estrés de mercado, DCOP mantenga una **convertibilidad mínima garantizada**, reforzando la confianza en el sistema y alineando los incentivos entre usuarios, deudores y redentores.

## 1. Liquidaciones (Mecanismo de Solvencia)

Las liquidaciones son el mecanismo de seguridad primario de Vankora. Aseguran que cada DCOP en circulación esté siempre respaldado por suficiente USDC.

### Condiciones de Liquidación
Un Vault (posición de deuda) se vuelve elegible para liquidación si su **Ratio de Colateral Individual (ICR)** cae por debajo del **Ratio Mínimo de Colateral (MCR)** del **130%**.

*   **Ejemplo:** Si un usuario tiene una deuda equivalente a $100 USD en DCOP, debe mantener al menos $130 USDC como colateral. Si el valor de su colateral baja a $129 USDC, el sistema permite que terceros cierren la posición para proteger la solvencia del protocolo.

### Cascada de Liquidación Híbrida
Vankora utiliza un modelo de dos fases para ejecutar liquidaciones de manera eficiente y garantizar que la deuda mala sea cubierta:

1.  **Prioridad 1: Pool de Estabilidad (Liquidación Interna)**
    Si el Pool de Estabilidad contiene DCOP depositados, el protocolo utilizará estos fondos automáticamente para absorber la deuda del Vault liquidado. Los DCOP correspondientes se queman del Pool, y el colateral (USDC) del Vault se transfiere a los depositantes del Pool con un descuento significativo.

    Los participantes del Pool de Estabilidad pueden esperar ganancias netas de las liquidaciones, ya que en la mayoría de los casos, el valor del colateral liquidadas será mayor que el valor de la deuda cancelada (ya que un Vault liquidado se espera que tenga un ICR justo por encima del 130%).

2.  **Prioridad 2: Liquidación de Mercado (Liquidación Externa)**
    Si el Pool de Estabilidad está vacío, el protocolo abre la liquidación al mercado libre (Permissionless). Cualquier actor externo (Bots/Keepers) puede pagar la deuda del Vault usando DCOP y recibir a cambio el colateral en USDC más un **Incentivo de Liquidación (Bonus)** fijo del valor total, incentivando el arbitraje inmediato.

Este sistema híbrido garantiza que las liquidaciones ocurran incluso en momentos de baja liquidez en los exchanges descentralizados (DEXs).

---

## 2. Redenciones (Mecanismo de Peg)

Las redenciones son el mecanismo de "última instancia" que crea un suelo duro (Hard Floor) para el precio del DCOP. Permite a cualquier poseedor de DCOP canjear sus tokens por USDC a valor nominal (Face Value), pagando la deuda de los usuarios más riesgosos del sistema.

### Activación Condicional

las redenciones en Vankora no están siempre activas.  únicamente cuando el precio de mercado del DCOP cae significativamente por debajo de su paridad (Depeg).

*   **Umbral de Activación:** DCOP < **0.97 COP** (Desviación > 3%).

## 3. Stability Pool (Fuente de Liquidez)

El Stability Pool es la primera línea de defensa para mantener la solvencia del sistema y ofrece una fuente de rendimiento real para los poseedores de DCOP.

### Funcionamiento.

Cualquier usuario puede depositar **DCOP** en el Stability Pool. Estos tokens quedan disponibles para que el protocolo los utilice automáticamente para ejecutar liquidaciones.

### Incentivos para el Depositante

A cambio de proveer esta liquidez de emergencia, los depositantes obtienen beneficios directos:
*   **Colateral con Descuento:** Cuando ocurre una liquidación, los DCOP del pool se queman para pagar la deuda, y el depositante recibe la parte proporcional del colateral (USDC) del Vault liquidado. Dado que la liquidación ocurre al 130% y la deuda es el 100%, el depositante está efectivamente adquiriendo USDC con un descuento significativo (aprox. ~10-15% de ganancia instantánea).

El Stability Pool permite a los usuarios acumular USDC pasivamente sin necesidad de operar bots de liquidación complejos.