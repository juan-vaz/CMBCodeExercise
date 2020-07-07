/*
* TestCommissions
* Contains unit test for the Commissions Domain Layer class
* @author Juan Vaz
*/
@isTest
private class TestCommissions {

    @TestSetup
    static void makeData(){
        new DataLayerTestUtility().createBasicTestScenario();
    }

	@isTest static void testCalculateCommissions(){

        List<Id> salesAgentIds = new List<Id>();
        for(Sales_Agent__c salesAgent : new salesAgentsSelector().getSalesAgents('Name')){
            salesAgentIds.add(salesAgent.Id);
        }
            
        List<Commission__c> commissionList =
                   new CommissionsSelector().getCommissionsByAgentsAndOpptyStage(salesAgentIds, CommissionsService.PENDING_OPPORTUNITY_STAGE);

        Test.startTest();

            Commissions comms = new Commissions(commissionList);
            Map<Id, Decimal> commissionsByAgentId = comms.calculateCommissions();

            // assert the commissions for the agent 0 = 0+10+20+30+40
            System.assertEquals(100, commissionsByAgentId.get(salesAgentIds.get(0)));
            // assert the commissions for the agent 1 = 50+60+70+80+90
            System.assertEquals(350, commissionsByAgentId.get(salesAgentIds.get(1)));

        Test.stopTest();


    }

    @isTest static void testAfterInsertEvent(){

        List<Sales_Agent__c> salesAgents = new salesAgentsSelector().getSalesAgents('Name');
        List<Commission__c> commissionListForAgent1 =
                   new CommissionsSelector().getCommissionsByAgentsAndOpptyStage(new List<Id>{salesAgents[1].Id}, CommissionsService.PENDING_OPPORTUNITY_STAGE);

        Test.startTest();
    
            // assert the commissions for the agent 0 = 0+10+20+30+40
            System.assertEquals(100, salesAgents[0].Amount_Pending__c);
            // assert the commissions for the agent 1 = 50+60+70+80+90
            System.assertEquals(350, salesAgents[1].Amount_Pending__c);

            // create 5 new commissions for the agent0
            List<Commission__c> comms = new List<Commission__c>();
            for(Integer i=0;i<5; i++){
                comms.add(new DataLayerTestUtility().createTestCommission(salesAgents[0].Id, 
                                            commissionListForAgent1[i].Opportunity__c, false));
            }
            insert comms;

            // refresh sales agents info from DB
            salesAgents = new salesAgentsSelector().getSalesAgents('Name');
            
            // assert the commissions for the agent 0 = 0+10+20+30+40+50+60+70+80+90
            System.assertEquals(450, salesAgents[0].Amount_Pending__c);
            // assert the commissions for the agent 1 = 50+60+70+80+90
            System.assertEquals(350, salesAgents[1].Amount_Pending__c);

        Test.stopTest();
    }
    
    @isTest static void testAfterUpdateEvent(){

        List<Sales_Agent__c> salesAgents = new salesAgentsSelector().getSalesAgents('Name');
        List<Commission__c> commissionListForAgent1 =
                   new CommissionsSelector().getCommissionsByAgentsAndOpptyStage(new List<Id>{salesAgents[1].Id}, CommissionsService.PENDING_OPPORTUNITY_STAGE);

        Test.startTest();
    
            // assert the commissions for the agent 0 = 0+10+20+30+40
            System.assertEquals(100, salesAgents[0].Amount_Pending__c);
            // assert the commissions for the agent 1 = 50+60+70+80+90
            System.assertEquals(350, salesAgents[1].Amount_Pending__c);

            // reasign all the commissions from agent1 to agent0
            for(Commission__c c : commissionListForAgent1){
                c.Sales_Agent__c = salesAgents[0].Id;
            }
            update commissionListForAgent1;

            // refresh sales agents info from DB
            salesAgents = new salesAgentsSelector().getSalesAgents('Name');
            
            // assert the commissions for the agent 0 = 0+10+20+30+40+50+60+70+80+90
            System.assertEquals(450, salesAgents[0].Amount_Pending__c);
            // assert the commissions for the agent 1 = 0
            System.assertEquals(0, salesAgents[1].Amount_Pending__c);

        Test.stopTest();
    }    

    @isTest static void testAfterDeleteEvent(){

        List<Sales_Agent__c> salesAgents = new salesAgentsSelector().getSalesAgents('Name');
        List<Commission__c> commissionList =
                   new CommissionsSelector().getCommissionsByAgentsAndOpptyStage(new List<Id>{salesAgents[1].Id}, CommissionsService.PENDING_OPPORTUNITY_STAGE);

        Test.startTest();
    
            // assert the commissions for the agent 0 = 0+10+20+30+40
            System.assertEquals(100, salesAgents[0].Amount_Pending__c);
            // assert the commissions for the agent 1 = 50+60+70+80+90
            System.assertEquals(350, salesAgents[1].Amount_Pending__c);

            // delete some of the commissions from agent1
            delete new List<Commission__c>{
                commissionList[0], commissionList[1], commissionList[2]
            }; 

            // refresh the sales agents from DB
            salesAgents = new salesAgentsSelector().getSalesAgents('Name');
            // assert the commissions for the agent 0 = 0+10+20+30+40
            System.assertEquals(100, salesAgents[0].Amount_Pending__c);
            // assert the commissions for the agent 1 = 80+90
            System.assertEquals(170, salesAgents[1].Amount_Pending__c);

            // delete all commissions
            delete [select id, Sales_Agent__c from Commission__c];

            // refresh the sales agents from DB
            salesAgents = new salesAgentsSelector().getSalesAgents('Name');
            // assert the commissions for the agent 0 = 0
            System.assertEquals(0, salesAgents[0].Amount_Pending__c);
            // assert the commissions for the agent 1 = 0
            System.assertEquals(0, salesAgents[1].Amount_Pending__c);

        Test.stopTest();
    }

}