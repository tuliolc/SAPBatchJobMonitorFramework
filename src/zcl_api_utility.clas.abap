CLASS zcl_api_utility DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS send_data
      IMPORTING it_data TYPE ztt_mon_data.

    CLASS-METHODS create_by_destination
      IMPORTING
        !iv_destination       TYPE c
      RETURNING
        VALUE(ro_http_client) TYPE REF TO if_http_client .

ENDCLASS.



CLASS ZCL_API_UTILITY IMPLEMENTATION.


  METHOD send_data.
    DATA: lv_json TYPE string,
          lo_http_client TYPE REF TO if_http_client.

    " Convert data to JSON
    lv_json = /ui2/cl_json=>serialize( data = it_data ).

    " Send HTTP POST request
*    cl_http_client=>create_by_url( EXPORTING url = 'https://api.example.com/metrics'
*                                   IMPORTING client = lo_http_client ).

    lo_http_client = create_by_destination( 'Z_AWS' ).

    lo_http_client->request->set_method( 'POST' ).
    lo_http_client->request->set_header_field( name = 'Content-Type' value = 'application/json' ).
    lo_http_client->request->set_cdata( lv_json ).

    lo_http_client->send( ).
    lo_http_client->receive( ).

    IF lo_http_client->response->get_status( ) <> 200.
      " Log error if needed
    ENDIF.
  ENDMETHOD.


  METHOD create_by_destination.
    DATA lo_http_client TYPE REF TO if_http_client.
    cl_http_client=>create_by_destination( EXPORTING  destination                = iv_destination
                                           IMPORTING  client                     = lo_http_client
                                           EXCEPTIONS argument_not_found         = 1
                                                      destination_not_found      = 2
                                                      destination_no_authority   = 3
                                                      plugin_not_active          = 4
                                                      internal_error             = 5
                                                      oa2c_set_token_error       = 6
                                                      oa2c_missing_authorization = 7
                                                      oa2c_invalid_config        = 8
                                                      oa2c_invalid_parameters    = 9
                                                      oa2c_invalid_scope         = 10
                                                      oa2c_invalid_grant         = 11
                                                      OTHERS                     = 12 ).

    IF sy-subrc EQ 0 AND lo_http_client IS BOUND.
      ro_http_client = lo_http_client.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
