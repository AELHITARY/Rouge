global with sharing class Utils {

    // Remplace les valeurs nulles
    public static Object replaceNull(Object obj){
        if(obj == null) obj = '';
        if(obj == 'null') obj = '';
        return obj;
    }

    // Remplace les valeurs nulles et encode pour les URL
    public static Object replaceNullURL(Object obj){
        return EncodingUtil.urlEncode(String.valueOf(replaceNull(obj)),'UTF-8');
    }

  public static boolean IsNullOrEmpty(string str) {
        return str == null || str.trim() == '';
    }

  public static Object [] splitArray (Object [] arr, Integer start, Integer count) {
    Object [] r = new Object [] {};

    if (0 > start || null == arr)
      return r;

    count = Math.min (count + start, arr.size ());
    if (0 >= count)
      return r;

    for (Integer i =  start; i < count; ++ i)
      r.add (arr [i]);

    return r;
  }

  public static Integer toInteger  (Object s) {
    if (null == s) return null;
    return Integer.valueOf (s);
  }

  public static String toString (Object o) {
    if (null == o) return null;
    return String.valueOf (o);
  }

  public static String [] toStringList (Object [] oo) {
    String [] r = new String [] {};

    for (Object o : oo)
      r.add (String.valueOf (o));

    return r;
  }

  public static string join (string [] ss, string s) {
    if (null == ss || ss.isEmpty ()) return '';
    if (null == s) s = '';

    iterator<string> i = ss.iterator ();

    string r = i.next ();

    while (i.hasNext ()) r += s + i.next ();

    return r;
  }

  public static String nullString2emptyString (String s) {
    return (String.isBlank(s)) ? ' ' : s;
  }

  global class PartialSelect implements Iterator<sObject []> {
    Integer index = 0;
    sObject [] buffer;
    Integer chunkSize = 2147483647;

    public PartialSelect (sObject [] oo, Integer cs) {
      buffer = oo;
      chunkSize = cs;
    }

    global Boolean hasNext () { return index < buffer.size (); }
    global Boolean getHasNext () { return hasNext (); }

    global sObject [] next (Integer customChunkSize) {
      sObject [] r = toSObject (splitArray (buffer, index, customChunkSize));
      index += r.size ();
      return r;
    }

    global sObject [] next () {
      return next (chunkSize);
    }
  }

  public static sObject [] toSObject (Object [] oo) {
    sObject [] dd = new sObject [] {};
    if (null != oo)
      for (Object o : oo) dd.add ((sObject) o);
    return dd;
  }
  public static boolean sameName(string a,string b){
    if(Utils.parsFrenchCharactersToEnglishCharacters(a)==Utils.parsFrenchCharactersToEnglishCharacters(b))
      return true;

    return false;
  }
  public static string parsFrenchCharactersToEnglishCharacters (string a){
    string res  = a;

    if(res!=null){
      res = res.replaceAll('-', ' ');
      res = res.replaceAll('À', 'A');
      res = res.replaceAll('Á', 'A');
      res = res.replaceAll('Â', 'A');
      res = res.replaceAll('Ã', 'A');
      res = res.replaceAll('Ä', 'A');
      res = res.replaceAll('Å', 'A');
      res = res.replaceAll('Æ', 'A');
      res = res.replaceAll('Ç', 'C');
      res = res.replaceAll('È', 'E');
      res = res.replaceAll('É', 'E');
      res = res.replaceAll('Ê', 'E');
      res = res.replaceAll('Ë', 'E');
      res = res.replaceAll('Ì', 'I');
      res = res.replaceAll('Í', 'I');
      res = res.replaceAll('Ï', 'I');
      res = res.replaceAll('Ò', 'O');
      res = res.replaceAll('Ó', 'O');
      res = res.replaceAll('Ô', 'O');
      res = res.replaceAll('Õ', 'O');
      res = res.replaceAll('Ö', 'O');
      res = res.replaceAll('Ù', 'U');
      res = res.replaceAll('Ú', 'U');
      res = res.replaceAll('Û', 'U');
      res = res.replaceAll('Ü', 'U');
      res = res.replaceAll('Ý', 'Y');
      res = res.replaceAll('à', 'a');
      res = res.replaceAll('á', 'a');
      res = res.replaceAll('â', 'a');
      res = res.replaceAll('ã', 'a');
      res = res.replaceAll('ä', 'a');
      res = res.replaceAll('å', 'a');
      res = res.replaceAll('æ', 'a');
      res = res.replaceAll('ç', 'c');
      res = res.replaceAll('è', 'e');
      res = res.replaceAll('é', 'e');
      res = res.replaceAll('ê', 'e');
      res = res.replaceAll('ë', 'e');
      res = res.replaceAll('ì', 'i');
      res = res.replaceAll('í', 'i');
      res = res.replaceAll('î', 'i');
      res = res.replaceAll('ï', 'i');
      res = res.replaceAll('ò', 'o');
      res = res.replaceAll('ó', 'o');
      res = res.replaceAll('ô', 'o');
      res = res.replaceAll('õ', 'o');
      res = res.replaceAll('ö', 'o');
      res = res.replaceAll('ù', 'u');
      res = res.replaceAll('ú', 'u');
      res = res.replaceAll('û', 'u');
      res = res.replaceAll('ü', 'u');
      res = res.replaceAll('ý', 'y');
      res = res.replaceAll('ÿ', 'y');
    }
    return res;
  }
}