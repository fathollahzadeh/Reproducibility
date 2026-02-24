WITH UserBadgeCount AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViewCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalViewCount, 0) AS TotalViewCount,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        U.Reputation
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCount UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.PostCount,
    U.TotalViewCount,
    U.QuestionCount,
    U.AnswerCount,
    RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
    RANK() OVER (ORDER BY U.BadgeCount DESC) AS BadgeRank,
    RANK() OVER (ORDER BY U.PostCount DESC) AS PostRank
FROM 
    UserPerformance U
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, U.BadgeCount DESC
LIMIT 10;
