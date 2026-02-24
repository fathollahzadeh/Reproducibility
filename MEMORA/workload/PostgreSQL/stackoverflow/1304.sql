
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId IN (1, 2) THEN P.ViewCount ELSE 0 END), 0) AS TotalViews,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        QuestionCount, 
        AnswerCount, 
        TotalViews,
        UserRank
    FROM 
        UserActivity
    WHERE 
        UserRank <= 10
),
UserBadges AS (
    SELECT 
        B.UserId, 
        B.Name AS BadgeName, 
        B.Class, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId, B.Name, B.Class
),
BadgeSummary AS (
    SELECT 
        UB.UserId, 
        STRING_AGG(UB.BadgeName || ' (' || UB.BadgeCount || ')', ', ') AS BadgeDetails
    FROM 
        UserBadges UB
    GROUP BY 
        UB.UserId
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalViews,
    TU.UserRank,
    COALESCE(BS.BadgeDetails, 'No Badges') AS BadgeSummary
FROM 
    TopUsers TU
LEFT JOIN 
    BadgeSummary BS ON TU.UserId = BS.UserId
ORDER BY 
    TU.UserRank;
