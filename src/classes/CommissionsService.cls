/**
 * CommissionsService
 * Service class 
 * @author Juan Vaz
 */
public with sharing class CommissionsService {

    public static final String NEW_OPPORTUNITY_STAGE = 'New';
    public static final String PENDING_OPPORTUNITY_STAGE = 'Pending';

    public void updateSalesAgentsPendingCommissions(List<Id> salesAgentIds){

        if(salesAgentIds != null && !salesAgentIds.isEmpty()){
            List<Commission__c> agentPendingCommissions = 
                    new CommissionsSelector().getCommissionsByAgentsAndOpptyStage(salesAgentIds, PENDING_OPPORTUNITY_STAGE);
            
            // store a map to avoid possible dups
            Map<Id, Sales_Agent__c> agentsToUpdate = new Map<Id, Sales_Agent__c>();
            Map<Id, Decimal> agentCommissionsMap = new Map<Id, Decimal>();

            // calculate the commissions amount for the agents involved
            if(agentPendingCommissions != null && !agentPendingCommissions.isEmpty()){
                agentCommissionsMap = new Commissions(agentPendingCommissions).calculateCommissions();
            }    

            for(Id agentId : salesAgentIds){
                if(agentCommissionsMap.containsKey(agentId)){
                    agentsToUpdate.put(agentId, 
                        new Sales_Agent__c(Id = agentId, Amount_Pending__c = agentCommissionsMap.get(agentId)));
                }else{
                    //for those who don't have comissions set amount 0
                    agentsToUpdate.put(agentId, 
                        new Sales_Agent__c(Id = agentId, Amount_Pending__c = 0));
                }
            }

            update agentsToUpdate.values();
        }
    }

}