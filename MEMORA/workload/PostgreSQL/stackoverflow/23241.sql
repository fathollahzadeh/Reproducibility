WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

PostStatistics AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    GROUP BY 
        P.OwnerUserId
),

UserEngagement AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(P.PostCount, 0) AS PostCount,
        COALESCE(B.BadgeCount, 0) AS BadgeCount,
        COALESCE(P.AverageScore, 0) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        PostStatistics P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        UserBadges B ON U.Id = B.UserId
)

SELECT 
    UEG.UserId,
    UEG.DisplayName,
    UEG.PostCount,
    UEG.BadgeCount,
    UEG.AverageScore,
    CASE 
        WHEN UEG.BadgeCount > 5 THEN 'High Activity'
        WHEN UEG.PostCount > 50 THEN 'Frequent Contributor'
        ELSE 'New User'
    END AS UserCategory
FROM 
    UserEngagement UEG
WHERE 
    UEG.PostCount IS NOT NULL
    AND UEG.BadgeCount IS NOT NULL
ORDER BY 
    UEG.PostCount DESC, UEG.BadgeCount DESC;