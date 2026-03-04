@IsTest
private class PSI_AppControllerTest {

    @IsTest
    static void testSearchAndSnapshotAndCompare() {
        Test.startTest();
        PSI_AppController.Info info = PSI_AppController.getInfo();
        List<PSI_AppController.UserPick> picks = PSI_AppController.searchUsers('ad', 5);
        Test.stopTest();

        System.assertEquals('0.1.0', info.version);

        Test.startTest();
        PSI_AppController.UserSnapshot snap = PSI_AppController.getUserSnapshot(UserInfo.getUserId(), false);
        PSI_AppController.Comparison cmp = PSI_AppController.compareUsers(UserInfo.getUserId(), UserInfo.getUserId(), false);
        Test.stopTest();

        System.assertNotEquals(null, snap);
        System.assertNotEquals(null, cmp);
        System.assertEquals(0, cmp.permissionSets.onlyA.size());
        System.assertEquals(0, cmp.groups.onlyB.size());
    }
}
