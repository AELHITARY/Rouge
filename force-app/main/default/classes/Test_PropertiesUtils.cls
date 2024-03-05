@isTest
private class Test_PropertiesUtils {

  private static final String   CST_STRING   = 'Azerty!';
  private static final Date     CST_DATE     = DateTime.newInstance(1990, 05, 01).date();
  private static final DateTime CST_DATETIME = DateTime.newInstance(1993, 08, 04, 17, 37, 45);
  private static final Boolean  CST_BOOLEAN  = TRUE;
  private static final Integer  CST_INTEGER  = 10;
  private static final Double   CST_DOUBLE   = 17.15;
    
  @isTest static void test_setAndGetProperties1() {
    PropertiesUtils.setStringValue('test.string', CST_STRING);
    PropertiesUtils.setDateValue('test.date', CST_DATE);
    PropertiesUtils.setDateTimeValue('test.dateTime', CST_DATETIME);
    PropertiesUtils.setBooleanValue('test.boolean', CST_BOOLEAN);
    PropertiesUtils.setIntegerValue('test.integer', CST_INTEGER);
    PropertiesUtils.setDoubleValue('test.double', CST_DOUBLE);
    
    Test.startTest();
    
    System.assertEquals(CST_STRING,   PropertiesUtils.getStringValue('test.string'));
    System.assertEquals(CST_DATE,     PropertiesUtils.getDateValue('test.date'));
    System.assertEquals(CST_DATETIME, PropertiesUtils.getDateTimeValue('test.dateTime'));
    System.assertEquals(CST_BOOLEAN,  PropertiesUtils.getBooleanValue('test.boolean'));
    System.assertEquals(CST_INTEGER,  PropertiesUtils.getIntegerValue('test.integer'));
    System.assertEquals(CST_DOUBLE,   PropertiesUtils.getDoubleValue('test.double'));
    
    Test.stoptest();
  }
  
  @isTest static void test_setAndGetProperties2() {
    PropertiesUtils.setStringValue('test.string', CST_STRING);
    PropertiesUtils.setDateValue('test.date', CST_DATE);
    PropertiesUtils.setDateTimeValue('test.dateTime', CST_DATETIME);
    PropertiesUtils.setBooleanValue('test.boolean', CST_BOOLEAN);
    PropertiesUtils.setIntegerValue('test.integer', CST_INTEGER);
    PropertiesUtils.setDoubleValue('test.double', CST_DOUBLE);
    
    Test.startTest();    
    
    System.assertEquals(null, PropertiesUtils.getStringValue('error.string'));
    System.assertEquals(null, PropertiesUtils.getDateValue('error.date'));
    System.assertEquals(null, PropertiesUtils.getDateTimeValue('error.dateTime'));
    System.assertEquals(null, PropertiesUtils.getBooleanValue('error.boolean'));
    System.assertEquals(null, PropertiesUtils.getIntegerValue('error.integer'));
    System.assertEquals(null, PropertiesUtils.getDoubleValue('error.double'));
    
    Test.stopTest();
  }
  
  @isTest static void test_setAndGetProperties3() {
    PropertiesUtils.setStringValue('test.string', CST_STRING);
    PropertiesUtils.setDateValue('test.date', CST_DATE);
    PropertiesUtils.setDateTimeValue('test.dateTime', CST_DATETIME);
    PropertiesUtils.setBooleanValue('test.boolean', CST_BOOLEAN);
    PropertiesUtils.setIntegerValue('test.integer', CST_INTEGER);
    PropertiesUtils.setDoubleValue('test.double', CST_DOUBLE);
    
    Test.startTest();    
    
    System.assertEquals(CST_STRING,   PropertiesUtils.getStringValue('error.string', CST_STRING));
    System.assertEquals(CST_DATE,     PropertiesUtils.getDateValue('error.date2', CST_DATE));
    System.assertEquals(CST_DATETIME, PropertiesUtils.getDateTimeValue('error.dateTime', CST_DATETIME));
    System.assertEquals(CST_BOOLEAN,  PropertiesUtils.getBooleanValue('error.boolean', CST_BOOLEAN));
    System.assertEquals(CST_INTEGER,  PropertiesUtils.getIntegerValue('error.integer', CST_INTEGER));
    System.assertEquals(CST_DOUBLE,   PropertiesUtils.getDoubleValue('error.double', CST_DOUBLE));
    
    Test.stoptest();
  }
  
  @isTest static void test_setAndGetProperties4() {
    PropertiesUtils.setStringValue(null, CST_STRING);
    PropertiesUtils.setDateValue(null, CST_DATE);
    PropertiesUtils.setDateTimeValue(null, CST_DATETIME);
    PropertiesUtils.setBooleanValue(null, CST_BOOLEAN);
    PropertiesUtils.setIntegerValue(null, CST_INTEGER);
    PropertiesUtils.setDoubleValue(null, CST_DOUBLE);
    
    String   defaultString   = 'DEFAULT';
    Date     defaultDate     = System.today();
    DateTime defaultDateTime = System.now();
    Boolean  defaultBoolean  = False;
    Integer  defaultInteger  = 123;
    Double   defaultDouble   = 987.523;
    
    Test.startTest();    

    System.assertEquals(defaultString, PropertiesUtils.getStringValue(null, defaultString));
    System.assertEquals(defaultDate, PropertiesUtils.getDateValue(null, defaultDate));
    System.assertEquals(defaultDateTime, PropertiesUtils.getDateTimeValue(null, defaultDateTime));
    System.assertEquals(defaultBoolean, PropertiesUtils.getBooleanValue(null, defaultBoolean));
    System.assertEquals(defaultInteger, PropertiesUtils.getIntegerValue(null, defaultInteger));
    System.assertEquals(defaultDouble, PropertiesUtils.getDoubleValue(null, defaultDouble));
    
    Test.stopTest();
  }
}