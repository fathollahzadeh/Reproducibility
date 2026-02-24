WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        PS.TotalPosts,
        PS.QuestionCount,
        PS.AnswerCount,
        PS.AvgScore
    FROM 
        UserReputation UR
    JOIN 
        PostStatistics PS ON UR.UserId = PS.OwnerUserId
    WHERE 
        UR.ReputationRank <= 10
),
RecentBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    WHERE 
        B.Date > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        B.UserId
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.QuestionCount,
    TU.AnswerCount,
    COALESCE(RB.BadgeCount, 0) AS RecentBadgeCount,
    TU.AvgScore,
    (SELECT COUNT(*) FROM Comments C WHERE C.UserId = TU.UserId) AS TotalComments,
    (SELECT STRING_AGG(CAST(PH.UserDisplayName AS VARCHAR), ', ') 
     FROM PostHistory PH 
     WHERE PH.UserId = TU.UserId 
     AND PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year') AS RecentEditors
FROM 
    TopUsers TU
LEFT JOIN 
    RecentBadges RB ON TU.UserId = RB.UserId
ORDER BY 
    TU.AvgScore DESC, TU.TotalPosts DESC;