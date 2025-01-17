# SAP Batch Job Monitoring Framework

## **Overview**
This framework enables active monitoring and logging of SAP batch job execution data. Designed for ABAP on Cloud, it collects metrics from registered data collectors and sends them to a specified AWS API endpoint in JSON format. The solution ensures operational integrity, extensibility, and scalability by leveraging modular design principles.

---

## **Key Features**
- Central dispatcher for periodic execution of registered data collectors.
- Generic interface for collectors to ensure extensibility.
- Logging of batch job execution data in a custom database table.
- Integration with AWS API for centralized monitoring.
- Comprehensive logging and error handling mechanisms.

---

## **Architecture**

### **Components**
1. **Central Dispatcher** (`ZMON_DISPATCHER`):
   - Periodically executed job that triggers all active data collectors.
   - Consolidates collected data and sends it to the API endpoint.

2. **Data Collectors**:
   - Each collector implements the `ZIF_MON_COLLECTOR` interface.
   - Encapsulates the logic for retrieving specific batch job execution data.

3. **Custom Tables**:
   - **ZTB_MON_CONFIG**: Stores metadata and configuration for registered collectors.
   - **ZTB_MON_LOG**: Logs the collected execution data.

4. **API Utility Class** (`ZCL_API_UTILITY`):
   - Handles serialization of collected data into JSON.
   - Manages HTTP communication with the AWS API using destinations (SM59).

---

## **Setup and Usage**

### **Step 1: Create Database Tables**

#### **Table: ZTB_MON_CONFIG**
Stores metadata for each registered collector.

```abap
@EndUserText.label : 'Table for each registered collector'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table ztb_mon_config {
  key client       : abap.clnt not null;
  key collector_id : abap.char(20) not null;
  description      : abap.char(20) not null;
  class_name       : abap.char(40) not null;
  active           : abap_boolean not null;
  last_exec_time   : abap.timn;
  exec_frequency   : abap.int4;
}
```

#### **Table: ZTB_MON_LOG**
Logs execution details of batch jobs.

```abap
@EndUserText.label : 'Table stores logs for executed collectors'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table ztb_mon_log {
  key client     : abap.clnt not null;
  key log_id     : abap.numc(10) not null;
  collector_id   : abap.char(20) not null;
  job_name       : abap.char(30) not null;
  job_status     : abap.char(1) not null;
  execution_time : abap.timn not null;
  duration       : abap.int4 not null;
  message        : abap.char(255);
}
```

#### **Structure: ZST_MON_CONFIG**
Structure of metadata for registered collector.

```abap
@EndUserText.label : 'Structure of ZTB_MON_CONFIG'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
define structure zst_mon_config {
  collector_id   : abap.char(20);
  description    : abap.char(20);
  class_name     : abap.char(40);
  active         : abap_boolean;
  last_exec_time : abap.timn;
  exec_frequency : abap.int4;
}
```

#### **Structure: ZST_MON_LOG**
Structure of logs execution details of batch jobs.

```abap
@EndUserText.label : 'Structure of batch job execution data'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
define structure zst_mon_data {
  job_name       : abap.char(20);
  job_id         : abap.char(8);
  job_status     : abap.char(1);
  execution_time : abap.timn;
  execution_date : abap.datn;
  duration       : abap.int4;
  message        : abap.string(0);
  created_by     : syuname;
}
```

#### **Structure: ZST_MON_DATA**
Structure of batch job execution data.

```abap
@EndUserText.label : 'Structure of batch job execution data'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
define structure zst_mon_data {
  job_name       : abap.char(20);
  job_id         : abap.char(8);
  job_status     : abap.char(1);
  execution_time : abap.timn;
  execution_date : abap.datn;
  duration       : abap.int4;
  message        : abap.string(0);
  created_by     : syuname;
}
```

#### **Table Type: ZTT_MON_DATA**
Table type of batch job execution data.

```abap
ZTT_MON_DATA type table of ZST_MON_DATA.
```

#### **Data Element: ZDE_MON_COLLECTOR_ID**
ID for Monitor Collector.

```abap
ZDE_MON_COLLECTOR_ID TYPE CHAR20.
```
---

### **Step 2: Define the Collector Interface**

#### **Interface: ZIF_MON_COLLECTOR**
Defines the structure and behavior of all data collectors.

```abap
INTERFACE zif_mon_collector
  PUBLIC .

  METHODS:
    collect_data
      RETURNING VALUE(rt_data) TYPE ztt_mon_data,

    get_collector_id
      RETURNING VALUE(rv_id) TYPE zde_mon_collector_id.

ENDINTERFACE.
```

---

### **Step 3: Implement a Data Collector**

#### **Class: ZCL_EXAMPLE_COLLECTOR**
Example implementation of the `ZIF_MON_COLLECTOR` interface.

```abap
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
```

---

### **Step 4: Configure the Central Dispatcher**

#### **Report: ZMON_DISPATCHER**

```abap
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
```

---

### **Step 5: Handle API Integration**

#### **Class: ZCL_API_UTILITY**
Manages communication with the API endpoint.

```abap
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
```

---

## **Quality Assurance**

1. **Unit Testing:**
   - Develop unit tests for collectors and utility classes.

2. **Integrated Testing:**
   - Develop integrated tests based on the unit ones for collectors, utility classes and report program.
   - Fill ZTB_MON_CONFIG with API endpoints for integration testing.
   - Execute singly, in background and as job scheduler multiple and simultaneous times.

3. **Error Handling:**
   - Log errors for failed API calls and collector executions.
   - Implement retry mechanisms for API communication.

4. **Documentation:**
   - Provide templates and guidelines for adding new collectors.
   - Maintain a detailed README for developers.

5. **Version Control:**
   - Use GitHub for version control, including code reviews and CI/CD pipelines.

---

## **Extending the Framework**

1. **Add a New Collector:**
   - Implement `ZIF_MON_COLLECTOR`.
   - Register the new collector in the `ZTB_MON_CONFIG` table.

2. **Modify Dispatcher Logic:**
   - Update `ZMON_DISPATCHER` to include additional steps if required.

3. **Enhance API Utility:**
   - Support new endpoints or additional authentication methods.

---

## **Conclusion**
This framework provides a robust foundation for proactive batch job monitoring in SAP. Its modular design ensures ease of extension, while integration with AWS enables centralized monitoring for enhanced operational integrity.

## **MindMap**
![image](https://github.com/user-attachments/assets/dc717962-edf9-40fc-a69b-afe1b0ceb4f5)

-> **Relevant information:** SQL operations on the TBTCO table are prohibited because it is classified as one of the 20 most critical base tables in SAP S/4HANA. Direct manipulation of its contents is not allowed due to its importance in the system.
Source: https://xiting.com/en/the-top-20-sap-it-base-tables-with-special-protection-requirements-in-sap-s4hana/ 
