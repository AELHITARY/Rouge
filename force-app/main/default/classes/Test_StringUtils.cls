@isTest
private class Test_StringUtils {

  static testMethod void test_trim() {
    System.assertEquals('Azerty !',StringUtils.trim('Azerty !'));
    System.assertEquals('Azerty !',StringUtils.trim('   Azerty !'));
    System.assertEquals('Azerty !',StringUtils.trim('Azerty !   '));
    System.assertEquals('Azerty !',StringUtils.trim('   Azerty !   '));
    System.assertEquals('Azerty !',StringUtils.trim('  \t  \n  Azerty !  \n  \t  '));
    System.assertEquals('', StringUtils.trim(''));
    System.assertEquals('', StringUtils.trim('   '));
    System.assertEquals('', StringUtils.trim('\n\t'));
    System.assertEquals('', StringUtils.trim('\n\t   \n\t   '));
    System.assertEquals(null, StringUtils.trim(null));
  }
  
  static testMethod void test_isEmpty() {
    System.assertEquals(false, StringUtils.isEmpty('Azerty !'));
    System.assertEquals(false, StringUtils.isEmpty('   Azerty !'));
    System.assertEquals(false, StringUtils.isEmpty('Azerty !   '));
    System.assertEquals(false, StringUtils.isEmpty('   Azerty !   '));
    System.assertEquals(false, StringUtils.isEmpty('  \t  \n  Azerty !  \n  \t  '));
    System.assertEquals(true, StringUtils.isEmpty(''));
    System.assertEquals(false, StringUtils.isEmpty('   '));
    System.assertEquals(false, StringUtils.isEmpty('\n\t'));
    System.assertEquals(false, StringUtils.isEmpty('\n\t   \n\t   '));
    System.assertEquals(true, StringUtils.isEmpty(null));
  } 
  
  static testMethod void test_trimToNull() {
    System.assertEquals('Azerty !', StringUtils.trimToNull('Azerty !'));
    System.assertEquals('Azerty !', StringUtils.trimToNull('   Azerty !'));
    System.assertEquals('Azerty !', StringUtils.trimToNull('Azerty !   '));
    System.assertEquals('Azerty !', StringUtils.trimToNull('   Azerty !   '));
    System.assertEquals('Azerty !', StringUtils.trimToNull('  \t  \n  Azerty !  \n  \t  '));
    System.assertEquals(null, StringUtils.trimToNull(''));
    System.assertEquals(null, StringUtils.trimToNull('   '));
    System.assertEquals(null, StringUtils.trimToNull('\n\t'));
    System.assertEquals(null, StringUtils.trimToNull('\n\t   \n\t   '));
    System.assertEquals(null, StringUtils.trimToNull(null));
  } 
  
  static testMethod void test_trimToEmpty() {
    System.assertEquals('Azerty !', StringUtils.trimToEmpty('Azerty !'));
    System.assertEquals('Azerty !', StringUtils.trimToEmpty('   Azerty !'));
    System.assertEquals('Azerty !', StringUtils.trimToEmpty('Azerty !   '));
    System.assertEquals('Azerty !', StringUtils.trimToEmpty('   Azerty !   '));
    System.assertEquals('Azerty !', StringUtils.trimToEmpty('  \t  \n  Azerty !  \n  \t  '));
    System.assertEquals('', StringUtils.trimToEmpty(''));
    System.assertEquals('', StringUtils.trimToEmpty('   '));
    System.assertEquals('', StringUtils.trimToEmpty('\n\t'));
    System.assertEquals('', StringUtils.trimToEmpty('\n\t   \n\t   '));
    System.assertEquals('', StringUtils.trimToEmpty(null));
  } 
  
  static testMethod void test_defaultIfEmpty() {
    System.assertEquals('Azerty !', StringUtils.defaultIfEmpty('Azerty !', 'Qsdfg#'));
    System.assertEquals('   Azerty !', StringUtils.defaultIfEmpty('   Azerty !', 'Qsdfg#'));
    System.assertEquals('Azerty !   ', StringUtils.defaultIfEmpty('Azerty !   ', 'Qsdfg#'));
    System.assertEquals('   Azerty !   ', StringUtils.defaultIfEmpty('   Azerty !   ', 'Qsdfg#'));
    System.assertEquals('  \t  \n  Azerty !  \n  \t  ', StringUtils.defaultIfEmpty('  \t  \n  Azerty !  \n  \t  ', 'Qsdfg#'));
    System.assertEquals('Qsdfg#', StringUtils.defaultIfEmpty('', 'Qsdfg#'));
    //System.assertEquals('   ', StringUtils.defaultIfEmpty('   ', 'Qsdfg#'));
    //System.assertEquals('\n\t', StringUtils.defaultIfEmpty('\n\t', 'Qsdfg#'));
    //System.assertEquals('\n\t   \n\t   ', StringUtils.defaultIfEmpty('\n\t   \n\t   ', 'Qsdfg#'));
    //System.assertEquals('Qsdfg#', StringUtils.defaultIfEmpty(null, 'Qsdfg#'));
  } 
}