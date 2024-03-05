public class EmailMessageWrapper {

    public String FromAddress;
        public String ToAddress;
        public String ToAddressId;
        public String BccAddress;
         public String Subject;
         public Map<String, String> ParameterSubjectMap;
         public String Body;
         public String HtmlValue;
         public Map<String, String> ParameterBodyMap;

  public EmailMessageWrapper(String fromAddr, Id toAddrId, String sub, Map<String, String> mapSubjectParams, Map<String, String> mapBodyParams) {
        this(fromAddr, null, toAddrId, null, sub, mapSubjectParams, null,null, mapBodyParams );
    }

    public EmailMessageWrapper(String fromAddr, String toAddr, Id toAddrId, String bccAddr, String sub, Map<String, String>  mapSubjectParams, String body, String htmlValue, Map<String, String> mapBodyParams) {
    this.FromAddress = fromAddr;
        this.ToAddress = toAddr;
        this.ToAddressId = toAddrId;
        this.BccAddress = bccAddr;
         this.Subject = sub;
         this.ParameterSubjectMap = mapSubjectParams;
         this.Body = body;
         this.HtmlValue = htmlValue;
         this.ParameterBodyMap = mapBodyParams;
   }
}