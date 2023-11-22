**----------------------------------------------------------------------*
** Preenchimento da BAPI (EXTENSION2)
**----------------------------------------------------------------------*
"Preenche referencia ao PO
APPEND INITIAL LINE TO lt_bapi_extension2[] ASSIGNING FIELD-SYMBOL(<fs_extension_ebeln>).
<fs_extension_ebeln>-structure  = 'ACCOUNTPAYABLE'.                                 "Estrutura da BAPI
<fs_extension_ebeln>-valuepart1 = '0000000001'.                                     "Numero do item/linha (vazio se for estrutura)
<fs_extension_ebeln>-valuepart2 = 'C_ACCIT'.                                        "Estrutura/Tabela da BAdI a ser preenchida
<fs_extension_ebeln>-valuepart3 = 'EBELN'.                                          "Campo da BAdI a ser preenchido
<fs_extension_ebeln>-valuepart4 = '4500000310'.                                     "Valor da BAPI a ser preenchimento na BAdi

"Preenche referencia ao item do PO
APPEND INITIAL LINE TO lt_bapi_extension2[] ASSIGNING FIELD-SYMBOL(<fs_extension_ebelp>).
<fs_extension_ebelp>-structure  = 'ACCOUNTPAYABLE'.                                 "Estrutura da BAPI
<fs_extension_ebelp>-valuepart1 = '0000000001'.                                     "Numero do item/linha (vazio se for estrutura)
<fs_extension_ebelp>-valuepart2 = 'C_ACCIT'.                                        "Estrutura/Tabela da BAdI a ser preenchida
<fs_extension_ebelp>-valuepart3 = 'EBELP'.                                          "Campo da BAdI a ser preenchido
<fs_extension_ebelp>-valuepart4 = '00010'.                                          "Valor da BAPI a ser preenchimento na BAdi

**----------------------------------------------------------------------*
** Implementação da Badi BADI_ACC_DOCUMENT
**----------------------------------------------------------------------*
CLASS zcl_enh_badi_acc_document DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_badi_interface .
    INTERFACES if_ex_acc_document .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS ZCL_ENH_BADI_ACC_DOCUMENT IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_ENH_BADI_ACC_DOCUMENT->IF_EX_ACC_DOCUMENT~CHANGE
* +-------------------------------------------------------------------------------------------------+
* | [--->] FLT_VAL                        TYPE        AWTYP
* | [<-->] C_ACCHD                        TYPE        ACCHD
* | [<-->] C_ACCIT                        TYPE        ACCIT_TAB
* | [<-->] C_ACCCR                        TYPE        ACCCR_TAB
* | [<-->] C_ACCWT                        TYPE        ACCWT_TAB
* | [<-->] C_ACCTX                        TYPE        ACCTX_TAB
* | [<-->] C_ACCFI                        TYPE        ACCFI_T(optional)
* | [<-->] C_EXTENSION2                   TYPE        BAPIPAREX_TAB_AC
* | [<-->] C_RETURN                       TYPE        BAPIRET2_T
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD if_ex_acc_document~change.

*****************************************************************************
***   Preenchimento dinamico para estrutura EXTENSION2:
**     STRUCTURE  -> Estrutura da BAPI
**     VALUEPART1 -> Numero do item/linha (vazio se for estrutura)
**     VALUEPART2 -> Estrutura/Tabela da BAdI a ser preenchida
**     VALUEPART3 -> Campo da BAdI a ser preenchido
**     VALUEPART4 -> Valor da BAPI a ser preenchimento na BAdI
** 
***    Exemplo - preenchimento da referencia ao Pedido/Item:
**     STRUCTURE        VALUEPART1  VALUEPART2  VALUEPART3  VALUEPART4
**     ACCOUNTPAYABLE   0000000001  C_ACCIT     EBELN       4500000310
**     ACCOUNTPAYABLE   0000000001  C_ACCIT     EBELP       00010
*****************************************************************************

    FIELD-SYMBOLS:
      <fs_table>  TYPE STANDARD TABLE,
      <fs_header> TYPE any,
      <fs_field>  TYPE any,
      <fs_extval> TYPE bapiparex.

    LOOP AT c_extension2 ASSIGNING FIELD-SYMBOL(<fs_key>)
      GROUP BY ( structure  = <fs_key>-structure    "Estrutura da BAPI
                 valuepart1 = <fs_key>-valuepart1   "Numero do item
                 valuepart2 = <fs_key>-valuepart2 ) "Estrutura da BAdI a ser preenchida
      ASSIGNING FIELD-SYMBOL(<fs_extgroup>).

      "Numero do item -> Tabela
      IF <fs_extgroup>-valuepart1 IS NOT INITIAL.

        "Recupera tabela da BAdI a ser preenchida
        UNASSIGN <fs_table>.
        ASSIGN (<fs_extgroup>-valuepart2) TO <fs_table>.
        CHECK sy-subrc IS INITIAL.

        TRY.

            "Recupera linha/item da tabela da BAdI a ser preenchida
            READ TABLE <fs_table> ASSIGNING <fs_header>
              WITH KEY ('BAPI_PARAM') = <fs_extgroup>-structure
                       ('BAPI_TABIX') = <fs_extgroup>-valuepart1.
            CHECK sy-subrc IS INITIAL.

            "Para campos da mesma linha
            LOOP AT GROUP <fs_extgroup> ASSIGNING <fs_extval>.

              "Recupera campo a ser preenchido
              UNASSIGN <fs_field>.
              ASSIGN COMPONENT <fs_extval>-valuepart3 OF STRUCTURE <fs_header> TO <fs_field>.
              CHECK sy-subrc IS INITIAL.

              "Preenche com valor a ser preenchimento
              <fs_field> = <fs_extval>-valuepart4.

            ENDLOOP.

          CATCH cx_root.
            UNASSIGN <fs_table>.
        ENDTRY.

        "Sem numero do item -> estrutura
      ELSE.

        "Recupera estrutura da BAdI a ser preenchida
        UNASSIGN <fs_header>.
        ASSIGN (<fs_extgroup>-valuepart2) TO <fs_header>.
        CHECK sy-subrc IS INITIAL.

        "Para campos da mesma linha
        LOOP AT GROUP <fs_extgroup> ASSIGNING <fs_extval>.

          "Recupera campo a ser preenchido
          UNASSIGN <fs_field>.
          ASSIGN COMPONENT <fs_extval>-valuepart3 OF STRUCTURE <fs_header> TO <fs_field>.
          CHECK sy-subrc IS INITIAL.

          "Preenche com valor a ser preenchimento
          <fs_field> = <fs_extval>-valuepart4.

        ENDLOOP.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_ENH_BADI_ACC_DOCUMENT->IF_EX_ACC_DOCUMENT~FILL_ACCIT
* +-------------------------------------------------------------------------------------------------+
* | [--->] FLT_VAL                        TYPE        AWTYP
* | [--->] I_ACCHD                        TYPE        ACCHD
* | [<-->] C_BAPI_ACCIT                   TYPE        ACCBAPIFD5
* | [<-->] C_ACCIT                        TYPE        ACCIT
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD if_ex_acc_document~fill_accit.
  ENDMETHOD.
ENDCLASS.