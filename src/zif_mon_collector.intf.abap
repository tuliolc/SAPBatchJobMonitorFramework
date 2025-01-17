INTERFACE zif_mon_collector
  PUBLIC .

  METHODS:
    collect_data
      RETURNING VALUE(rt_data) TYPE ztt_mon_data,

    get_collector_id
      RETURNING VALUE(rv_id) TYPE zde_mon_collector_id.

ENDINTERFACE.
