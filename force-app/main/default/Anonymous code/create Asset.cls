Id accountId = [SELECT Id FROM Account WHERE Name = 'ARTISANT' limit 1].Id;
Id chantierId = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier1'].Id;
Id contactId = [SELECT Id FROM Contact WHERE Name = 'Nelly Mermel' limit 1].Id;
Id orderId = null ; // [SELECT Id FROM Order WHERE Name = 'Commande 1' limit 1].Id; // missing
Id orderItemId = null ; //[SELECT Id FROM OrderItem WHERE Name = 'Produit 1' limit 1].Id; // missing
Id productId = [SELECT Id FROM Product2 WHERE Name = 'Fenêtre aluminium gamme Eklair+' limit 1].Id;
Id recordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Menuiserie' limit 1].Id;
ID assetId = null ; //[SELECT Id FROM Asset WHERE Name = 'Fenêtre aluminium gamme Eklair+' limit 1].Id;

asset a = new asset();

a.AccountId =   accountId ; //Account
//a.asIdentifiedDifficultie__c = false ;
//a.AssetLevel = 2 ;
a.AssetServicedById = null ; //accountId ; //Account
a.AverageUptimePerDay = 24.0 ;
a.chantier__c =  chantierId ; //Chantier
a.ContactId =  contactId ; //Contact
//a.controlTime__c = 0.0 ;
a.customerOrder__c =  orderId ; //Order
a.height__c = 215.0 ;
//a.Id = '02iAP000000wsl2YAA' ;
//a.interventionTime__c = 0.0 ;
a.invoicedAmount__c = 0.0 ;
//a.isBillable__c = true ;
a.IsCompetitorProduct = false ;
//a.IsDeleted = false ;
a.IsInternal = true ;
a.isLegacy__c = false ;
//a.isLocked__c = false ;
//a.isOrderable__c = false ;
//a.isOrderCancelled__c = false ;
//a.isOrdered__c = false ;
//a.isOrderLocked__c = false ;
///a.isParentLock__c = false ;
//a.leaf__c = 1 ;
a.Name = 'OTHFRAISPOSE - Prestation technique et d\'installation ';
a.orderItem__c =  orderItemId ; //OrderItem
a.ParentId =  assetId ; //Asset
//a.pretaxAmountFormula__c = 145.55 ;
a.Product2Id = '01t68000000CS3vAAG' ; //Product2
//a.ProductCode = 'OTHFRAISPOSE' ;
//a.ProductDescription = 'Systématique et obligatoire. Représente 20% du sous-total prix de base + options valorisées. ';
//a.productName__c = 'Prestation technique et d\'installation' ;
//a.PurchaseDate = '2024-02-21' ;
a.Quantity = 1.0 ;
a.RecordTypeId = '01268000000g1YaAAI' ; //Prestation technique et d'installation
a.refundedAmount__c = 0.0 ;
//a.RootAssetId = '02iAP000000wskoYAA' ;
a.SBQQ__Bundled__c = false ;
a.SBQQ__Bundle__c = false ;
a.SBQQ__ComponentDiscountedByPackage__c = false ;
a.SBQQ__FromServiceCloud__c = false ;
a.SBQQ__PricingMethod__c = 'List' ;
a.stageName__c = 'Enregistrement' ;
a.Status = 'Validé' ;
//a.SumDowntime = 0.0 ;
//a.SumUnplannedDowntime = 0.0 ;
//a.TEST__c = false ;
//a.unit__c = UNIT ;
a.width__c = 148.0   ;

insert a;
system.debug('assetId: ' + a.Id);
-----------------------------
  
------------------------
   static Opportunity createOpportunity(String name, ID accId, Account autreAcc, Id chaId, Boolean toInsert) {
        Opportunity opp = new Opportunity(Name = name,
                                          AccountId = accId,
                                          Type = 'Nouveau',
                                          StageName = 'Analyse',
                                          chantier__c = chaId,
                                          CloseDate = System.today() + 10,
                                          Probability = 10, Pricebook2Id = '01sD0000000GV94IAG');
        
                if(toInsert) 
                insert opp;
        return opp;
    }
    
Id accountId = [SELECT Id FROM Account WHERE Name = 'ARTISANT' limit 1].Id;
Id chantierId = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier1'].Id;
Id contactId = [SELECT Id FROM Contact WHERE Name = 'Nelly Mermel' limit 1].Id;
Id orderId = null ; // [SELECT Id FROM Order WHERE Name = 'Commande 1' limit 1].Id; // missing
Id orderItemId = null ; //[SELECT Id FROM OrderItem WHERE Name = 'Produit 1' limit 1].Id; // missing
Id productId = [SELECT Id FROM Product2 WHERE Name = 'Fenêtre aluminium gamme Eklair+' limit 1].Id;
Id recordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Menuiserie' limit 1].Id;
ID assetId = null ; //[SELECT Id FROM Asset WHERE Name = 'Fenêtre aluminium gamme Eklair+' limit 1].Id;
Id Pricebook2Id = '01sD0000000GV94IAG';

Opportunity opp = createOpportunity('Opportunité 1', accountId, null, chantierId, true);
system.debug('=====Oppo====: ' + opp.Id);
---------


public static Quote createQuote(String name, Id rtId, Id accId,Id OppId, String status, Date dateDevis, Integer totalTTC, Integer acompteAttendu, 
                                    String source, Id operationId, Boolean toInsert) {
                                        Quote devis = new Quote(OpportunityId = oppId,
                                                                Pricebook2Id = '01sD0000000GV94IAG',
                                                                Name = name,
                                                                dateDevis__c = dateDevis,
                                                                referenceDate__c = dateDevis,
                                                                compte__c = accId,
                                                                source__c = source,
                                                                typeContrat__c = Constants.QUOTE_TYPECONTRAT_STANDARD,
                                                                moyenTransmissionClient__c = 'Par email',
                                                                //autreCompte__c = opp.autreCompte__c,
                                                                modeFinancement__c = 'PAIEMENT COMPTANT',
                                                                total_TTC_devis__c = totalTTC,
                                                                mntAcompteAttendu__c = acompteAttendu,
                                                                operation__c = operationId);
                                        
                                        if(rtId != null) 
                                            devis.RecordTypeId = rtId;
                                        if(String.isNotBlank(status)) {
                                            devis.Status = status;
                                            devis.forcageEtat__c = status;
                                        }
                                        
                                        if(toInsert) 
                                            insert devis;
                                        return devis;
                                    }
    
Id accountId = [SELECT Id FROM Account WHERE Name = 'ARTISANT' limit 1].Id;
Id chantierId = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier1'].Id;
Id contactId = [SELECT Id FROM Contact WHERE Name = 'Nelly Mermel' limit 1].Id;
Id orderId = null ; // [SELECT Id FROM Order WHERE Name = 'Commande 1' limit 1].Id; // missing
Id orderItemId = null ; //[SELECT Id FROM OrderItem WHERE Name = 'Produit 1' limit 1].Id; // missing
Id productId = [SELECT Id FROM Product2 WHERE Name = 'Fenêtre aluminium gamme Eklair+' limit 1].Id;
Id recordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Menuiserie' limit 1].Id;
ID assetId = null ; //[SELECT Id FROM Asset WHERE Name = 'Fenêtre aluminium gamme Eklair+' limit 1].Id;
Id Pricebook2Id = '01sD0000000GV94IAG';
Id OpportunityId= '006AU00000Bqcm5YAB';

quote devis = createQuote('Dev 1', null, accountId, OpportunityId, 'Draft', Date.today(), 1000, 100, 'PASSAGE MAGASIN', null, true);
system.debug('=====Quote====: ' + devis.Id);
---------------------------------

static Asset createAsset(Id rtId, String name, Id customerOrderId, Id quoteId, Id product2Id, Id orderItemId, Id chantierId, Id accountId, Boolean toInsert){
        Asset newAsset = new Asset(RecordTypeId = rtId, 
                                    customerOrder__c = customerOrderId, 
                                    Product2Id=product2Id, 
                                    chantier__c = chantierId, 
                                    Name = name, 
                                    //quoteId = quoteId,
                                    Quantity = 1,
                                    orderItem__c = orderItemId,
                                    leaf__c = '1',
                                    AccountId = accountId);
        if(toInsert){
            insert newAsset;
        }
        return newAsset;
    }

     static WorkOrder createWorkOrder(Id rtId, String customerOrder, Boolean toInsert){
        WorkOrder wo = new WorkOrder(RecordTypeId=rtId, 
                                    Duration=120, 
                                    DurationType='Minutes',
                                    customerOrder__c = customerOrder);
        if(toInsert){
            insert wo;
        }
        return wo;
    }
    static WorkOrderLineItem createWorkOrderLineItem(Id WorkOrderId, Id AssetId, Boolean toInsert){
        WorkOrderLineItem woli = new WorkOrderLineItem(WorkOrderId=WorkOrderId, AssetId=AssetId, Duration=120, DurationType='Minutes');
        if(toInsert){
            insert woli;
        }
        return woli;
    }

    static Order createCustomerOrder(String accountId, String chantierId, Id quoteId, String salesEntityId, String serviceEntityId, Boolean toInsert){
        Order newCustomerOrder = new Order(
            //Status = 'Registered', 
            AccountId = accountId, 
            salesEntity__c = salesEntityId,
            serviceEntity__c = serviceEntityId,
            chantier__c = chantierId,
            EffectiveDate = Date.today(), 
            Pricebook2Id = '01sD0000000GV94IAG',
            RecordTypeId = '01268000000g1GnAAI',
            shippingName__c ='TEST', 
            billingName__c ='TEST', 
            quoteId = quoteId,
            ShippingCity ='Paris', 
            ShippingPostalCode ='75000', 
            BillingCity ='Paris', 
            BillingPostalCode ='75000',
            minCommercialDelay__c = 2,
            maxCommercialDelay__c = 10,
            Status = Constants.ORDER_STATUS_REGISTERED 
        );

        if(toInsert){
            insert newCustomerOrder;
        }
        return newCustomerOrder;
    }

     
    
Id accountId = [SELECT Id FROM Account WHERE Name = 'ARTISANT' limit 1].Id;
Id chantierId = [SELECT Id FROM Chantier__c WHERE Name = 'Chantier1'].Id;
Id contactId = [SELECT Id FROM Contact WHERE Name = 'Nelly Mermel' limit 1].Id;
Id orderId = null ; // [SELECT Id FROM Order WHERE Name = 'Commande 1' limit 1].Id; // missing
Id orderItemId = null ; //[SELECT Id FROM OrderItem WHERE Name = 'Produit 1' limit 1].Id; // missing
Id productId = [SELECT Id FROM Product2 WHERE Name = 'Fenêtre aluminium gamme Eklair+' limit 1].Id;
Id recordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Menuiserie' limit 1].Id;
ID assetId = null ; //[SELECT Id FROM Asset WHERE Name = 'Fenêtre aluminium gamme Eklair+' limit 1].Id;
Id Pricebook2Id = '01sD0000000GV94IAG';
Id OpportunityId= '006AU00000Bqcm5YAB';
id quoteId = '0Q0AU000000DaDl0AK';


String RTDevNameworkOrderService0 = [SELECT Id FROM RecordType WHERE Name = 'Demande de rendez-vous de service' LIMIT 1].Id;   
String RTDevNameworkOrderService = [SELECT Id FROM RecordType WHERE Name = 'K/K - FSL Work Order' LIMIT 1].Id;
Id RTDevNameAsset = [SELECT Id FROM RecordType WHERE Name = 'Menuiserie' LIMIT 1].Id;
Order newCustomerOrder = createCustomerOrder(accountId, chantierId, quoteId, null, null, true);
//newCustomerOrder.chantier__c=chantierId;
//update newCustomerOrder;
Asset assetCustomerOrder = createAsset(RTDevNameAsset, 'Fenêtre aluminium gamme Eklair+', newCustomerOrder.Id, quoteId, productId, orderItemId, chantierId, accountId, true);
assetCustomerOrder.leaf__c = '2';
insert assetCustomerOrder;     
WorkOrder wo = createWorkOrder(RTDevNameworkOrderService, null, true);  
//WorkOrderLineItem woli =  createWorkOrderLineItem(wo.Id, assetCustomerOrder.Id, true);
WorkOrderLineItem woli = createWorkOrderLineItem(wo.Id, assetCustomerOrder.Id, true);


system.debug('assetId: ' + assetCustomerOrder.Id);
system.debug('wo: ' + wo.Id);
system.debug('woli: ' + woli.Id);
system.debug('newCustomerOrder: ' + newCustomerOrder.Id);
