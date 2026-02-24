
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        AVG(COALESCE(EXTRACT(EPOCH FROM (COALESCE(P.LastActivityDate, P.CreationDate) - P.CreationDate)), 0)) AS AvgActiveTime
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        TotalBounties,
        AvgActiveTime,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank
    FROM 
        UserStats
), 
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.AnswerCount,
    TU.QuestionCount,
    COALESCE(UB.BadgeNames, 'No Badges') AS Badges,
    TU.TotalBounties,
    TU.AvgActiveTime,
    TU.ReputationRank,
    TU.PostCountRank
FROM 
    TopUsers TU
LEFT JOIN 
    UserBadges UB ON TU.UserId = UB.UserId
WHERE 
    TU.PostCount > 10
ORDER BY 
    TU.Reputation DESC, TU.PostCount DESC
LIMIT 50;
