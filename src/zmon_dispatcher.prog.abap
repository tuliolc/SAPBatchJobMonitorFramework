*&---------------------------------------------------------------------*
*& Report ZMON_DISPATCHER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zmon_dispatcher.

DATA: lt_collectors      TYPE TABLE OF REF TO zif_mon_collector,
      lt_monitoring_data TYPE ztt_mon_data.

" Fetch active collectors
SELECT class_name
  INTO TABLE @DATA(lt_classes)
  FROM zmon_config
  WHERE active = 'X'.

" Instantiate and execute collectors
LOOP AT lt_classes INTO DATA(ls_class).
  TRY.
      DATA(lo_collector) = CAST zif_mon_collector ( NEW (ls_class-class_name) ).
      APPEND lo_collector TO lt_collectors.
    CATCH cx_root.
      " Log instantiation errors
  ENDTRY.
ENDLOOP.

LOOP AT lt_collectors INTO DATA(lo_collector).
  APPEND LINES OF lo_collector->collect_data( ) TO lt_monitoring_data.
ENDLOOP.

" Send consolidated data to API
zcl_api_utility=>send_data( lt_monitoring_data ).
