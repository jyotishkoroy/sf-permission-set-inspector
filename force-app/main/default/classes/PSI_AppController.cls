/**
 * Permission Set Inspector
 *
 * Copyright (c) 2026 Jyotishko Roy (https://orcid.org/0009-0000-2837-4731)
 * Licensed under the MIT License - see LICENSE file in the project root.
 */
public with sharing class PSI_AppController {

    public class Info {
        @AuraEnabled public String version;
        @AuraEnabled public String apiVersion;
        @AuraEnabled public Boolean sandbox;
        @AuraEnabled public String orgId;
        @AuraEnabled public String userId;
        @AuraEnabled public String username;
    }

    public class UserPick {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String username;
        @AuraEnabled public String email;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String profileName;
        @AuraEnabled public Datetime lastLoginDate;
    }

    public class AssignmentRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String developerName;
        @AuraEnabled public String kind; // PermissionSet | PermissionSetGroup
    }

    public class UserSnapshot {
        @AuraEnabled public UserPick user;
        @AuraEnabled public String warning;
        @AuraEnabled public List<AssignmentRow> permissionSets;
        @AuraEnabled public List<AssignmentRow> groups;
        @AuraEnabled public List<AssignmentRow> groupIncludedPermissionSets;
        @AuraEnabled public Boolean groupExpansionAvailable;
    }

    public class DiffBucket {
        @AuraEnabled public List<AssignmentRow> onlyA;
        @AuraEnabled public List<AssignmentRow> onlyB;
        @AuraEnabled public List<AssignmentRow> both;
    }

    public class Comparison {
        @AuraEnabled public UserPick userA;
        @AuraEnabled public UserPick userB;
        @AuraEnabled public DiffBucket permissionSets;
        @AuraEnabled public DiffBucket groups;
        @AuraEnabled public String warning;
    }

    @AuraEnabled(cacheable=true)
    public static Info getInfo() {
        Info i = new Info();
        i.version = '0.1.0';
        i.apiVersion = '55.0';
        i.sandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        i.orgId = UserInfo.getOrganizationId();
        i.userId = UserInfo.getUserId();
        i.username = UserInfo.getUserName();
        return i;
    }

    @AuraEnabled(cacheable=true)
    public static List<UserPick> searchUsers(String queryText, Integer limitSize) {
        Integer lim = (limitSize == null || limitSize <= 0) ? 15 : Math.min(25, limitSize);
        String q = (queryText == null) ? '' : queryText.trim();
        if (q.length() < 2) return new List<UserPick>();

        String likeTerm = '%' + q + '%';

        List<UserPick> out = new List<UserPick>();
        for (User u : [
            SELECT Id, Name, Username, Email, IsActive, LastLoginDate, Profile.Name
            FROM User
            WHERE (Name LIKE :likeTerm OR Username LIKE :likeTerm OR Email LIKE :likeTerm)
            ORDER BY IsActive DESC, Name ASC
            LIMIT :lim
        ]) {
            out.add(toUserPick(u));
        }
        return out;
    }

    @AuraEnabled(cacheable=true)
    public static UserSnapshot getUserSnapshot(Id userId, Boolean includeGroupExpansion) {
        if (userId == null) throw new AuraHandledException('Missing userId.');

        User u = [
            SELECT Id, Name, Username, Email, IsActive, LastLoginDate, Profile.Name
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ];

        UserSnapshot snap = new UserSnapshot();
        snap.user = toUserPick(u);
        snap.permissionSets = new List<AssignmentRow>();
        snap.groups = new List<AssignmentRow>();
        snap.groupIncludedPermissionSets = new List<AssignmentRow>();
        snap.groupExpansionAvailable = false;

        for (PermissionSetAssignment psa : [
            SELECT PermissionSetId, PermissionSet.Name, PermissionSet.DeveloperName, PermissionSet.IsOwnedByProfile
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
            ORDER BY PermissionSet.Name
        ]) {
            if (psa.PermissionSet != null && psa.PermissionSet.IsOwnedByProfile == false) {
                snap.permissionSets.add(newAssignment(psa.PermissionSetId, psa.PermissionSet.Name, psa.PermissionSet.DeveloperName, 'PermissionSet'));
            }
        }

        try {
            for (PermissionSetGroupAssignment pga : [
                SELECT PermissionSetGroupId, PermissionSetGroup.MasterLabel, PermissionSetGroup.DeveloperName
                FROM PermissionSetGroupAssignment
                WHERE AssigneeId = :userId
                ORDER BY PermissionSetGroup.MasterLabel
            ]) {
                snap.groups.add(newAssignment(pga.PermissionSetGroupId, pga.PermissionSetGroup.MasterLabel, pga.PermissionSetGroup.DeveloperName, 'PermissionSetGroup'));
            }
        } catch (Exception ex) {
            snap.warning = 'Permission Set Group membership not available: ' + ex.getMessage();
        }

        if (includeGroupExpansion == true && !snap.groups.isEmpty()) {
            try {
                Set<Id> groupIds = new Set<Id>();
                for (AssignmentRow g : snap.groups) groupIds.add(g.id);

                Map<Id, AssignmentRow> seen = new Map<Id, AssignmentRow>();
                for (PermissionSetGroupComponent c : [
                    SELECT PermissionSetId, PermissionSet.Name, PermissionSet.DeveloperName, PermissionSet.IsOwnedByProfile
                    FROM PermissionSetGroupComponent
                    WHERE PermissionSetGroupId IN :groupIds
                ]) {
                    if (c.PermissionSet == null) continue;
                    if (c.PermissionSet.IsOwnedByProfile == true) continue;
                    if (!seen.containsKey(c.PermissionSetId)) {
                        seen.put(c.PermissionSetId, newAssignment(c.PermissionSetId, c.PermissionSet.Name, c.PermissionSet.DeveloperName, 'PermissionSet'));
                    }
                }

                snap.groupIncludedPermissionSets = sortRows(seen.values());
                snap.groupExpansionAvailable = true;
            } catch (Exception ex) {
                snap.groupExpansionAvailable = false;
                snap.warning = appendWarn(snap.warning, 'Group expansion unavailable: ' + ex.getMessage());
            }
        }

        return snap;
    }

    @AuraEnabled(cacheable=true)
    public static Comparison compareUsers(Id userAId, Id userBId, Boolean includeGroupExpansion) {
        if (userAId == null || userBId == null) throw new AuraHandledException('Select two users.');

        UserSnapshot a = getUserSnapshot(userAId, includeGroupExpansion);
        UserSnapshot b = getUserSnapshot(userBId, includeGroupExpansion);

        Comparison c = new Comparison();
        c.userA = a.user;
        c.userB = b.user;
        c.warning = appendWarn(a.warning, b.warning);

        c.permissionSets = diffBucket(a.permissionSets, b.permissionSets);
        c.groups = diffBucket(a.groups, b.groups);

        return c;
    }

    private static UserPick toUserPick(User u) {
        UserPick p = new UserPick();
        p.id = u.Id;
        p.name = u.Name;
        p.username = u.Username;
        p.email = u.Email;
        p.isActive = u.IsActive;
        p.lastLoginDate = u.LastLoginDate;
        p.profileName = (u.Profile == null ? null : u.Profile.Name);
        return p;
    }

    private static AssignmentRow newAssignment(Id id, String name, String devName, String kind) {
        AssignmentRow r = new AssignmentRow();
        r.id = id;
        r.name = name;
        r.developerName = devName;
        r.kind = kind;
        return r;
    }

    private static DiffBucket diffBucket(List<AssignmentRow> aRows, List<AssignmentRow> bRows) {
        Map<Id, AssignmentRow> aMap = new Map<Id, AssignmentRow>();
        Map<Id, AssignmentRow> bMap = new Map<Id, AssignmentRow>();

        for (AssignmentRow r : (aRows == null ? new List<AssignmentRow>() : aRows)) aMap.put(r.id, r);
        for (AssignmentRow r : (bRows == null ? new List<AssignmentRow>() : bRows)) bMap.put(r.id, r);

        Set<Id> both = new Set<Id>(aMap.keySet());
        both.retainAll(bMap.keySet());

        Set<Id> onlyA = new Set<Id>(aMap.keySet());
        onlyA.removeAll(bMap.keySet());

        Set<Id> onlyB = new Set<Id>(bMap.keySet());
        onlyB.removeAll(aMap.keySet());

        DiffBucket d = new DiffBucket();
        d.both = rowsFromIds(both, aMap);
        d.onlyA = rowsFromIds(onlyA, aMap);
        d.onlyB = rowsFromIds(onlyB, bMap);
        return d;
    }

    private static List<AssignmentRow> rowsFromIds(Set<Id> ids, Map<Id, AssignmentRow> src) {
        List<AssignmentRow> out = new List<AssignmentRow>();
        for (Id i : ids) {
            if (src.containsKey(i)) out.add(src.get(i));
        }
        out.sort(new AssignmentRowSort());
        return out;
    }

    private static List<AssignmentRow> sortRows(Iterable<AssignmentRow> rows) {
        List<AssignmentRow> out = new List<AssignmentRow>();
        for (AssignmentRow r : rows) out.add(r);
        out.sort(new AssignmentRowSort());
        return out;
    }

    private class AssignmentRowSort implements Comparator<AssignmentRow> {
        public Integer compare(AssignmentRow a, AssignmentRow b) {
            String an = a == null ? '' : (a.name == null ? '' : a.name);
            String bn = b == null ? '' : (b.name == null ? '' : b.name);
            Integer c = an.compareToIgnoreCase(bn);
            if (c != 0) return c;
            String ad = a == null ? '' : (a.developerName == null ? '' : a.developerName);
            String bd = b == null ? '' : (b.developerName == null ? '' : b.developerName);
            return ad.compareToIgnoreCase(bd);
        }
    }

    private static String appendWarn(String a, String b) {
        if (String.isBlank(a)) return b;
        if (String.isBlank(b)) return a;
        return a + ' | ' + b;
    }
}
