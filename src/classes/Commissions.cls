/**
 * Domain Layer class for Commission__c sObject
 * @Author Juan Vaz
 */
public with sharing class Commissions {

    @TestVisible List<Commission__c> records;
    
    public Commissions(){
        this.records = new List<Commission__c>();
    }

    public Commissions(List<Commission__c> comms){
        this.records = comms;
    }

    /**
     * Calculates the Sales Agent Commissions for all records 
     * @return returns a Map from Sales Agent Id to Commissions Amount
     */ 
    public Map<Id, Decimal> calculateCommissions(){
        Map<Id, Decimal> agentCommissionsMap = new Map<Id, Decimal>();
        if(this.records != null){
            for(Commission__c comm : records){

                if(comm.Opportunity__r != null && comm.Opportunity__r.Amount__c != null){
                    Decimal commissionAmount = 0;
                    if(agentCommissionsMap.containsKey(comm.Sales_Agent__c)){
                        commissionAmount = agentCommissionsMap.get(comm.Sales_Agent__c);
                    }
                    agentCommissionsMap.put(comm.Sales_Agent__c, 
                            commissionAmount + comm.Opportunity__r.Amount__c);

                }
            }
        }
        return agentCommissionsMap;        
    }

    /**
     * After Insert trigger event handler
     * Updates all related sales agents commissions
     * for every inserted Commission having a pending associated oppty
     */
    public void onAfterInsert(){
        if(this.records != null && !records.isEmpty()){
            // get the list of record ids
            List<Id> commIds = new List<Id>(new Map<Id, Commission__c>(records).keySet());
            // get all pending commissions with related info
            List<Commission__c> pendingCommissions = new CommissionsSelector().
                        getCommissionsByIdsAndOpptyStage(commIds, CommissionsService.PENDING_OPPORTUNITY_STAGE);
            
            // gather all related sales agents 
            Set<Id> salesAgentIds = new Set<Id>();
            for(Commission__c comm: pendingCommissions){
                salesAgentIds.add(comm.Sales_Agent__c);
            }

            // update all related sales agents pending commissions
            new CommissionsService().updateSalesAgentsPendingCommissions(new List<Id>(salesAgentIds));
        }
    }

    /**
     * After Update trigger event handler
     * Updates all related sales agents commissions
     * for every Commission having opportunity changed from/to a pending oppty
     * or having the sales agent changed and a pending associated oppty
     * @param  oldMap Trigger old map
     */
    public void onAfterUpdate(Map<Id, Commission__c> oldMap){
        if(this.records != null && !records.isEmpty()){
            
            Set<Id> pendingInvolvedOpportunityIds 
                        = getPendingOpptyIdsSet(oldMap);

            // gather all related sales agents 
            Set<Id> salesAgentIds = new Set<Id>();
        
            for(Commission__c newComms : this.records){

                // if either the old oppty or the new oppty was pending then look further
                if(pendingInvolvedOpportunityIds.contains(newComms.Opportunity__c) ||
                    pendingInvolvedOpportunityIds.contains(oldMap.get(newComms.Id).Opportunity__c)){
                    
                    // if the sales agent has changed
                    if(newComms.Sales_Agent__c != oldMap.get(newComms.Id).Sales_Agent__c){
                        
                        // then add both agents to recalculate
                        salesAgentIds.add(newComms.Sales_Agent__c);
                        salesAgentIds.add(oldMap.get(newComms.Id).Sales_Agent__c);
                        
                    }else{ // if the agent hasn't changed

                        // if the opportunity has changed
                        if(newComms.Opportunity__c != oldMap.get(newComms.Id).Opportunity__c){
                            salesAgentIds.add(newComms.Sales_Agent__c);
                        }

                    } 
                }
            }

            // update all related sales agents commissions
            new CommissionsService().updateSalesAgentsPendingCommissions(new List<Id>(salesAgentIds));
    
        }
    }
    
    /**
     * Returns a set with the opportunity ids involved in the updates 
     * having pending stage
     * @param  oldMap Trigger old map
     */
    private Set<Id> getPendingOpptyIdsSet(Map<Id, Commission__c> oldMap){
        
        // gather all involved opportunity ids
        Set<Id> opptyIds = new Set<Id>();
        for(Commission__c newComms : this.records){
            opptyIds.add(newComms.Opportunity__c);
            opptyIds.add(oldMap.get(newComms.Id).Opportunity__c);
        }

        // retrieve the pending opportunities involved in the updates
        List<Opportunity> pendingInvolvedOpportunities
             = new OpportunitiesSelector().getOpportunitiesByIdsAndStage(
                    new List<Id>(opptyIds), CommissionsService.PENDING_OPPORTUNITY_STAGE);

        // store the pending opportunities ids in a set
        Set<Id> pendingInvolvedOpportunityIds = new Set<Id>();
        if(pendingInvolvedOpportunities != null && !pendingInvolvedOpportunities.isEmpty()){
            pendingInvolvedOpportunityIds = new Map<Id, Opportunity>(pendingInvolvedOpportunities).keySet();
        }

        return pendingInvolvedOpportunityIds;
        
    }

    /**
     * After Delete trigger event handler
     * Updates all related sales agents commissions
     * for every deleted Commission
     */
    public void onAfterDelete(){
        
        if(this.records != null && !records.isEmpty()){
            
            // gather all related sales agents 
            List<Id> salesAgentIds = new List<Id>();
            for(Commission__c comm : this.records){
                salesAgentIds.add(comm.Sales_Agent__c);
            }
            System.debug(salesAgentIds);
            // update all related sales agents commissions
            new CommissionsService().updateSalesAgentsPendingCommissions(salesAgentIds);
        }
    }

}