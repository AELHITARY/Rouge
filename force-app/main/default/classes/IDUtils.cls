public class IDUtils {
  public static List<ID> getIDs(List<sObject> items) {
    /* >>> F.G., le 12/11/2012 
    List<ID> IDs = new List<ID>();
    
    for (sObject item : items)
      IDs.add(item.id);
    
    return IDs; 
       <<< F.G., le 12/11/2012 */
    return new List<ID>((new Map<ID, sObject>(items)).keySet());   
    /* --- F.G., le 12/11/2012 */ 
  }
}