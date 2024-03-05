//-- --------------------------------------------------------------------------------- --
//-- *
//-- Fichier     : TR022_CreditMemoLine
//-- Modifié par : SOPRA STERIA
//-- Modifié le  : 21/09/2021
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public without sharing class TR022_CreditMemoLine {
    
    /**
    * @description Méthode pour calculer le montant et les taux TVA sur l'avoir selon les infos des lignes
    * @param userContext Contexte utilisateur
    */
    public static void calculateVATAmount(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }
        System.debug('### DEBUT TR022_CreditMemoLine.calculateVATAmount');
        
        Map<Id, CreditMemoLine__c> oldcreditMemoLines = (Map<Id, CreditMemoLine__c>)Trigger.oldMap;
        List<CreditMemoLine__c> newcreditMemoLines = (List<CreditMemoLine__c>)Trigger.new;  
        List<CreditMemoLine__c> creditMemoLinesList = new List<CreditMemoLine__c>();  
        List<String> creditMemosIds = new List<String>();  
        Map<String, List<CreditMemoLine__c>> creditMemoLinesMap = new Map<String, List<CreditMemoLine__c>>();
        List<CreditMemo__c> creditMemoToUpdate = new List<CreditMemo__c>();  
        List<String> linesDeleted = new List<String>();  

        // Selon le type d'exécution, récupération des lignes
        if(Trigger.isDelete) {
            creditMemoLinesList = oldcreditMemoLines.values();
        } else {
            creditMemoLinesList = newcreditMemoLines;
        }

        // Récupération des avoirs à mettre à jour
        for(CreditMemoLine__c credMemoLines : creditMemoLinesList){
            CreditMemoLine__c oldcreditMemoLine = oldcreditMemoLines == null ? null : oldcreditMemoLines.get(credMemoLines.id); 
            // Seulement pour les lignes liées à des facture et non historique
            if(String.isNotBlank(credMemoLines.creditMemo__c) && String.isBlank(credMemoLines.legacyReference__c) && 
                !AlreadyUsed.isUsed('TR022_CreditMemoLine.calculateVATAmount', credMemoLines.creditMemo__c) &&
                (Trigger.isInsert || Trigger.isDelete ||
                ( Trigger.isUpdate && oldcreditMemoLine != null && oldcreditMemoLine.VATAmount__c != credMemoLines.VATAmount__c))
            ) {
                System.debug('## CreditMemo Id: ' + credMemoLines.creditMemo__c);
                creditMemosIds.add(credMemoLines.creditMemo__c);
                // Si ligne supprimée, on stocke son ID pour ne pas prendre en compte dans le calcul
                if(Trigger.isDelete) {
                    linesDeleted.add(credMemoLines.Id);
                }
            }  
        }
        
        // SOQL - Pour chaque avoirs, récupération des lignes
        if(!creditMemosIds.isEmpty()) {
            List<CreditMemoLine__c> credMemoLinesList;
            for(CreditMemoLine__c line : [SELECT Id, creditMemo__c, VATRate__c, VATAmount__c FROM CreditMemoLine__c 
                                        WHERE creditMemo__c IN :creditMemosIds AND Id NOT IN :linesDeleted]) {
                // Construction d'une MAP de lignes par avoirs
                String key = line.creditMemo__c;
                if(creditMemoLinesMap.get(key) == null) {
                    credMemoLinesList = new List<CreditMemoLine__c>();
                } else {
                    credMemoLinesList = creditMemoLinesMap.get(key);
                }
                credMemoLinesList.add(line);
                creditMemoLinesMap.put(key, credMemoLinesList);
            }
            System.debug('## creditMemoLinesMap: ' + creditMemoLinesMap);
    
            // Pour chaque avoirs, calcul du montant TVA selon les lignes
            for(String creditMemoId : creditMemoLinesMap.keySet()) {
                System.debug('## Calultate for CreditMemo Id: ' + creditMemoId);
                System.debug('## Lines: ' + creditMemoLinesMap.get(creditMemoId));
                Map<Decimal, Decimal> montantsTVA = new Map<Decimal, Decimal>();
                // Récupération des montants par taux
                for (CreditMemoLine__c line : creditMemoLinesMap.get(creditMemoId)) {
                    System.debug('## Line: '+line.Id+' / '+line.VATRate__c+' / '+line.VATAmount__c);
                    Decimal montantTVA = montantsTVA.get(line.VATRate__c);
                    if (montantTVA == null) {
                        montantTVA = line.VATAmount__c;
                    } else {
                        montantTVA += line.VATAmount__c;
                    }
                    montantsTVA.put(line.VATRate__c, montantTVA);
                }
                // Mise à jour des champs de la facture selon le taux
                List<Decimal> vatRateList = new List<Decimal>(montantsTVA.keySet());
                System.debug('## VAT Rate: ' + vatRateList);
                if(vatRateList != null) {
                    // Création de l'objet facture avec Id existant
                    CreditMemo__c creditMemoUp = new CreditMemo__c(Id = creditMemoId, 
                                                            VATRate1__c=null, VATAmount1__c=null,
                                                            VATRate2__c=null, VATAmount2__c=null,
                                                            VATRate3__c=null, VATAmount3__c=null); 
                    // Mise à jour des champs de l'avpor
                    vatRateList.sort();
                    if (vatRateList.size() >= 1) {
                        creditMemoUp.VATRate1__c = vatRateList.get(0);
                        creditMemoUp.VATAmount1__c = montantsTVA.get(vatRateList.get(0));
                    }
                    if (vatRateList.size() >= 2) {
                        creditMemoUp.VATRate2__c = vatRateList.get(1);
                        creditMemoUp.VATAmount2__c = montantsTVA.get(vatRateList.get(1));
                    }
                    if (vatRateList.size() >= 3) {
                        creditMemoUp.VATRate3__c = vatRateList.get(2);
                        creditMemoUp.VATAmount3__c = montantsTVA.get(vatRateList.get(2));
                    }
                    creditMemoUp.VATAmount1__c = (creditMemoUp.VATAmount1__c != null) ? creditMemoUp.VATAmount1__c.setScale(2) : null;
                    creditMemoUp.VATAmount2__c = (creditMemoUp.VATAmount2__c != null) ? creditMemoUp.VATAmount2__c.setScale(2) : null;
                    creditMemoUp.VATAmount3__c = (creditMemoUp.VATAmount3__c != null) ? creditMemoUp.VATAmount3__c.setScale(2) : null;

                    System.debug('## CreditMemo to up: ' + creditMemoUp);
                    creditMemoToUpdate.add(creditMemoUp);
                }
            }
        }

        if(!creditMemoToUpdate.isEmpty()) {
            update creditMemoToUpdate;
        }
        System.debug('### FIN TR022_CreditMemoLine.calculateVATAmount');
    }

    /**
    * @description Mise à jour des numéros de ligne avant suppression d'une ligne
    * @param userContext Contexte utilisateur
    */
    public static void updateLinesNumberDelete(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_CreditMemoLine.updateLinesNumberDelete');
        Map<Id, CreditMemoLine__c> oldCreditMemoLines = (Map<Id, CreditMemoLine__c>)Trigger.oldMap;
        List<String> creditMemosIds = new List<String>();  
        Decimal numDeleteLine=null;

        // Récupération des IDs des avoirs
        for (CreditMemoLine__c credLines : oldCreditMemoLines.values()) {
            if (String.isNotBlank(credLines.CreditMemo__c) && String.isBlank(credLines.legacyReference__c) && 
                !AlreadyUsed.isUsed('TR022_CreditMemoLine.updateLinesNumberDelete', credLines.CreditMemo__c)) 
            {
                creditMemosIds.add(credLines.CreditMemo__c);
            }
        }
                
        if(!creditMemosIds.isEmpty()) {
            // SOQL - SELECT - Liste de toutes les lignes des avoirs impactés
            List<CreditMemoLine__c> CreditMemoLineBefore = [SELECT Id, CreditMemo__c, lineNumber__c FROM CreditMemoLine__c WHERE CreditMemo__c IN :creditMemosIds];
            for (String creditMemo : creditMemosIds) {
                System.debug('## creditMemo: ' + creditMemo);
                // Pour toutes les lignes supprimés, on décremente le compteur
                for (CreditMemoLine__c line : oldCreditMemoLines.values()) {
                    if(line.CreditMemo__c == creditMemo) {
                        // Récupération du numéro de ligne supprimé
                        numDeleteLine = line.lineNumber__c;
                        System.debug('## Num Ligne supp: ' + numDeleteLine);
                    }
                }
                // Variables de stockage
                Decimal lastLineNumber = 0;
                // CRM-461 réajustement des numéros de ligne après suppression
                for (CreditMemoLine__c lineBefore : CreditMemoLineBefore){
                    System.debug('## Supression ligne:' + numDeleteLine + ' ' + lineBefore.lineNumber__c);
                    if(lineBefore.lineNumber__c > numDeleteLine) {
                        // Mise à jour du champ
                        lastLineNumber = lineBefore.lineNumber__c - 1;
                        System.debug('## Num Format: ' + lastLineNumber);
                        lineBefore.lineNumber__c = lastLineNumber;
                    }
                }
            }

            if(!CreditMemoLineBefore.isEmpty()) {
                update CreditMemoLineBefore;
            }
        }
        System.debug('### FIN TR022_CreditMemoLine.updateLinesNumberDelete');
    }

    /**
    * @description Mise à jour des numéros des lignes
    * @param userContext Contexte utilisateur
    */
    public static void updateLinesNumber(UserContext userContext) {
        if (!Trigger.isExecuting) {
            return;
        }

        System.debug('### DEBUT TR022_CreditMemoLine.updateLinesNumber');
        List<CreditMemoLine__c> newCreditMemoLines = (List<CreditMemoLine__c>)Trigger.new;  
        List<String> creditMemosIds = new List<String>();  

        // Récupération des IDs des avoirs
        for (CreditMemoLine__c credLines : newCreditMemoLines) {
            if (String.isNotBlank(credLines.CreditMemo__c) && String.isBlank(credLines.legacyReference__c) && 
                !AlreadyUsed.isUsed('TR022_CreditMemoLine.updateLinesNumber', credLines.CreditMemo__c)) 
            {
                creditMemosIds.add(credLines.CreditMemo__c);
            }
        }
        
        if(!creditMemosIds.isEmpty()) {
            // SOQL - Récupération du nombre de lignes par avoirs
            Map<String, Integer> CreditMemoLineNumber = new Map<String, Integer>();
            for (AggregateResult nbLine : [SELECT CreditMemo__c, COUNT(Id) total FROM CreditMemoLine__c WHERE CreditMemo__c IN :creditMemosIds GROUP BY CreditMemo__c]) {
                CreditMemoLineNumber.put((String)nbLine.get('CreditMemo__c'), (Integer)nbLine.get('total'));
            }
            System.debug('## CreditMemoLineNumber: ' + CreditMemoLineNumber);

            // Mise à jour des champs
            for (String creditMemo: creditMemosIds) {
                System.debug('## creditMemo: ' + creditMemo);
                Integer lineNumber = (CreditMemoLineNumber.get(creditMemo) == null) ? 0 : CreditMemoLineNumber.get(creditMemo);
                System.debug('## Numero: ' + lineNumber);
                for(CreditMemoLine__c line : newCreditMemoLines) {
                    if (line.CreditMemo__c == creditMemo) {
                        // Mise à jour du champ
                        lineNumber++;                        
                        System.debug('## Num Format: ' + lineNumber);
                        line.lineNumber__c = lineNumber;
                    }
                }
            }
        }
        System.debug('### FIN TR022_CreditMemoLine.updateLinesNumber');
    }

    /**
    * @description Mise à jour des numéros des lignes
    * @param userContext Contexte utilisateur
    */
    public static void calculateAmounts(UserContext userContext) {
        System.debug('### DEBUT TR022_CreditMemoLine.calculateAmounts');
        List<CreditMemoLine__c> newCreditMemoLines = (List<CreditMemoLine__c>)Trigger.new;  
        List<String> creditMemosIds = new List<String>();  
        List<CreditMemo__c> creditMemoListToUpdate = new List<CreditMemo__c>();

        // Récupération des IDs des avoirs
        for (CreditMemoLine__c credLines : newCreditMemoLines) {
            if (String.isNotBlank(credLines.creditMemo__c) && String.isBlank(credLines.legacyReference__c)) 
            {
                creditMemosIds.add(credLines.creditMemo__c);
            }
        }

        if(!creditMemosIds.isEmpty()) {
            // SOQL - SELECT - Liste de toutes les lignes des avoirs impactés
            List<CreditMemoLine__c> creditMemoLines = [SELECT Id, creditMemo__c, amount__c, pretaxAmount__c FROM CreditMemoLine__c WHERE creditMemo__c IN :creditMemosIds];
            List<CreditMemo__c> creditMemos = [SELECT Id, autoComputedAmount__c, amount__c, pretaxAmount__c FROM CreditMemo__c WHERE id IN :creditMemosIds];
            // Mise à jour des montants de l'avoir (ROLL UP des lignes avec condition)
            for (CreditMemo__c creditMemo : creditMemos) {
                System.debug('## CreditMemo: ' + creditMemo);
                if(creditMemo.autoComputedAmount__c){
                    Decimal amount = 0;
                    Decimal pretaxAmount = 0;
                    for (CreditMemoLine__c line : creditMemoLines) {
                        if(line.creditMemo__c == creditMemo.Id) {
                            amount = amount + line.amount__c;
                            pretaxAmount = pretaxAmount + line.pretaxAmount__c;
                        }
                    }
                    creditMemo.amount__c = amount;
                    creditMemo.pretaxAmount__c = pretaxAmount;
                    creditMemo.amount__c = (creditMemo.amount__c != null) ? creditMemo.amount__c.setScale(2) : null;
                    creditMemo.pretaxAmount__c = (creditMemo.pretaxAmount__c != null) ? creditMemo.pretaxAmount__c.setScale(2) : null;
                    creditMemoListToUpdate.add(creditMemo);
                    System.debug('## amount: ' + creditMemo.amount__c);
                    System.debug('## pretaxAmount: ' + creditMemo.pretaxAmount__c);
                }
            }
        }

        if(!creditMemoListToUpdate.isEmpty()) {
            update creditMemoListToUpdate;
        }

        System.debug('### FIN TR022_CreditMemoLine.calculateAmounts');
    }
}