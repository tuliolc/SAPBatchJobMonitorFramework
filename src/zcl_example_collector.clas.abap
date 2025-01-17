CLASS zcl_example_collector DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_mon_collector.
  PRIVATE SECTION.
    METHODS collect_batch_data RETURNING VALUE(rt_data) TYPE ztt_mon_data.
ENDCLASS.

CLASS ZCL_EXAMPLE_COLLECTOR IMPLEMENTATION.

  METHOD collect_batch_data.
    SELECT jobname, jobcount, status, strtdate, strttime, prdmins, reluname
      FROM tbtc_job_data
      WHERE status IN ('S', 'E') " Success/Error
      INTO TABLE @DATA(lt_batch_data).

    LOOP AT lt_batch_data INTO DATA(ls_data).
      APPEND VALUE #( job_id = ls_data-jobcount
                      job_name = ls_data-jobname
                      job_status = ls_data-status
                      execution_time = ls_data-strttime
                      execution_date = ls_data-strtdate
                      created_by = ls_data-reluname
                      duration = ls_data-prdmins ) TO rt_data.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_mon_collector~collect_data.
    rt_data = collect_batch_data( ).
  ENDMETHOD.

  METHOD zif_mon_collector~get_collector_id.
    rv_id = 'EXAMPLE_COLLECTOR'.
  ENDMETHOD.
ENDCLASS.
