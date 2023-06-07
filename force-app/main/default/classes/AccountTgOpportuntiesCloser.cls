public with sharing class AccountTgOpportuntiesCloser implements Tiger.AfterUpdate{

    /**
     * if the Account was updated and the field Close_Open_Opportunities__c checked,
     * close all the related open Opportunties
     */
    public Boolean inScopeAfterUpdate(SObject newRecord){

        return TriggerFieldsFlipper.flipped(newRecord, 'Close_Open_Opportunities__c');
    }

    /**
     * In the real world scenario, this logic should be implemented in a batch class if any Account may have
     * bulk open Opportunties associated. For demonstration purpose, it is simplified.
     */
    public void processAfterUpdate(SObject[] scope){

        Opportunity[] opportunities = [SELECT Id FROM Opportunity WHERE AccountId IN :scope AND IsClosed = FALSE];

        for(Opportunity opprotunity : opportunities){
            
            opprotunity.StageName = 'Closed Lost';
        }

        System.debug('opportunities: ' + opportunities);

        update opportunities;
    }
}