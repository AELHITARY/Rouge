public class StringUtils {
  public static final String EMPTY = '';
  
  public static String trim(String str){
    return (str == null) ? null : str.trim();
  }

  public static boolean isEmpty(String str) {
    return str == null || str.length() == 0;
  }
  
  public static String trimToNull(String str) {
    String ts = trim(str);
    return String.isBlank(ts) ? null : ts;
  }  
  
  public static String trimToEmpty(String str) {
    String ts = trim(str);
    return String.isBlank(ts) ? EMPTY : ts;
  }
  
  public static String defaultIfEmpty(String str, String defaultStr) {
    return String.isBlank(str) ? defaultStr : str;
  }
}