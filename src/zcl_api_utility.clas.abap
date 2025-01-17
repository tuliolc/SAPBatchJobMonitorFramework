CLASS zcl_api_utility DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS send_data
      IMPORTING it_data TYPE ztt_mon_data.
ENDCLASS.



CLASS ZCL_API_UTILITY IMPLEMENTATION.


  METHOD send_data.
    DATA: lv_json TYPE string,
          lo_http_client TYPE REF TO if_http_client.

    " Convert data to JSON
    lv_json = /ui2/cl_json=>serialize( data = it_data ).

    " Send HTTP POST request
    cl_http_client=>create_by_url( EXPORTING url = 'https://api.example.com/metrics'
                                   IMPORTING client = lo_http_client ).

    lo_http_client->request->set_method( 'POST' ).
    lo_http_client->request->set_header_field( name = 'Content-Type' value = 'application/json' ).
    lo_http_client->request->set_cdata( lv_json ).

    lo_http_client->send( ).
    lo_http_client->receive( ).

    IF lo_http_client->response->get_status( ) <> 200.
      " Log error if needed
    ENDIF.
  ENDMETHOD.
ENDCLASS.
