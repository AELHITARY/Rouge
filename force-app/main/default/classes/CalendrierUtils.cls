public class CalendrierUtils {

    private static final String REPOSITORY = 'k-store.calendar';
    private static final String[] EMPTY = new String[0];

    public static String[] getMagasinsKStore(final String code) {
        if (String.isBlank(code))
            return EMPTY;

        List<String> magasins = new List<String>();
        magasins.add(code);
        
        Map<String, Mapping__c> mappings = Mapping__c.getAll();
        for (Mapping__c mapping : mappings.values())
            if (REPOSITORY.equalsIgnoreCase(mapping.repository__c) && code.equalsIgnoreCase(mapping.pickValue__c))
                magasins.add(mapping.convertedValue__c);

        return magasins;
    }
}