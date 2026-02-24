WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END), 0) AS TagWikiCount,
        COALESCE(SUM(CASE WHEN P.LastActivityDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month' THEN 1 ELSE 0 END), 0) AS RecentActivityCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TagWikiCount,
        RecentActivityCount,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM 
        UserPostStats
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
FinalStats AS (
    SELECT 
        TU.UserId,
        TU.DisplayName,
        TU.PostCount,
        TU.QuestionCount,
        TU.AnswerCount,
        TU.TagWikiCount,
        TU.RecentActivityCount,
        UB.BadgeCount,
        UB.BadgeNames
    FROM 
        TopUsers TU
    LEFT JOIN 
        UserBadges UB ON TU.UserId = UB.UserId
)
SELECT 
    FS.DisplayName,
    FS.PostCount,
    FS.QuestionCount,
    FS.AnswerCount,
    FS.TagWikiCount,
    FS.RecentActivityCount,
    FS.BadgeCount,
    FS.BadgeNames
FROM 
    FinalStats FS
WHERE 
    FS.PostCount > 10 
ORDER BY 
    FS.PostCount DESC
LIMIT 10;