public class AlreadyUsed {
  	private static Set<String> cachedObjects = new Set<String>();
  
  	public static Boolean isUsed(String operation, ID id) {
		String ident = operation + ':' + id;
		
		if (cachedObjects.contains(ident))
		return true;
		cachedObjects.add(ident);
		return false;
  	}

	public static Boolean isUsed2(String operation, String id) {
		String ident = operation + ':' + id;
		if (cachedObjects.contains(ident))
			return true;
		cachedObjects.add(ident);
		return false;
  	}
}