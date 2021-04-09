@isTest(isParallel=true)
public class AuthorizationCodeTest {
    @isTest
    static void flow() {
        Schema.Account acct = new Schema.Account(Name = 'Test');

        insert acct;

        Test.startTest();

        System.assert(
            !AuthorizationCode.lists(acct.Id),
            'It should not have contained an authorization code'
        );

        String code = AuthorizationCode.generate(acct.Id, 60 * 60);

        System.assertEquals(6, code.length(), 'The code should have been 6 characters long');
        System.assertEquals(AuthorizationCode.Status.VALID, AuthorizationCode.match(code, acct.Id));

        String newCode = AuthorizationCode.generate(acct.Id, 2);

        System.assert(!code.equalsIgnoreCase(newCode), 'The code should have changed');
        System.assertEquals(
            AuthorizationCode.Status.INVALID,
            AuthorizationCode.match(newCode, acct.Id)
        );

        vosh.Utils.sleep(4);

        System.assertEquals(
            AuthorizationCode.Status.EXPIRED,
            AuthorizationCode.match(newCode, acct.Id)
        );

        Test.stopTest();
    }
}
