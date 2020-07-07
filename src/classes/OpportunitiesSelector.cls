/**
 * OpportunitiesSelector - Selector class for Opportunity object
 * @author Juan Vaz
 */
public with sharing class OpportunitiesSelector {

    /**
     * Retrieves all the Opportunities filtered by stage
     * @param stage opportunity stage
     * @return list of opportunites having the stage passed in
     */
    public List<Opportunity> getOpportunitiesByStage(String stage){
        return getOpportunitiesByIdsAndStage(null, stage);
    }

    /**
     * Retrieves all the Opportunities filtered by id list and stage
     * @param opptyIds opportunity ids list
     * @param stage opportunity stage
     * @return list of opportunites having the stage passed in
     */
    public List<Opportunity> getOpportunitiesByIdsAndStage(List<Id> opptyIds, String stage){
        String query =  'SELECT id, Stage__c, Amount__c '+
                        'FROM Opportunity ';
        
        String condition = '';
        if(opptyIds !=  null && !opptyIds.isEmpty()){
            condition += ' WHERE Id IN: opptyIds';
        }                        
                        
        if(String.isNotBlank(stage)){
            condition += (String.isBlank(condition) ? ' WHERE ' : ' AND ') + 'Stage__c =: stage';
        }                        

        return Database.query(query + condition);
    }


}