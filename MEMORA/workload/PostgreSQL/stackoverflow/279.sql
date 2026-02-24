WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        MAX(U.CreationDate) AS AccountCreationDate
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
PostActivity AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        MAX(P.LastActivityDate) AS LastPostActivity
    FROM Posts P
    WHERE P.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
    GROUP BY P.OwnerUserId
),
CommentStats AS (
    SELECT 
        C.UserId,
        COUNT(C.Id) AS CommentCount,
        SUM(C.Score) AS TotalCommentScore
    FROM Comments C
    GROUP BY C.UserId
),
UserPostSummary AS (
    SELECT 
        UR.UserId,
        UR.Reputation,
        COALESCE(PA.PostCount, 0) AS PostCount,
        COALESCE(PA.TotalScore, 0) AS TotalPostScore,
        COALESCE(CS.CommentCount, 0) AS CommentCount,
        COALESCE(CS.TotalCommentScore, 0) AS TotalCommentScore,
        UR.BadgeCount,
        UR.AccountCreationDate
    FROM UserReputation UR
    LEFT JOIN PostActivity PA ON UR.UserId = PA.OwnerUserId
    LEFT JOIN CommentStats CS ON UR.UserId = CS.UserId
)
SELECT 
    UDS.UserId,
    UDS.Reputation,
    UDS.PostCount,
    UDS.TotalPostScore,
    UDS.CommentCount,
    UDS.TotalCommentScore,
    UDS.BadgeCount,
    UDS.AccountCreationDate,
    RANK() OVER (ORDER BY UDS.Reputation DESC) AS ReputationRank
FROM UserPostSummary UDS
WHERE UDS.Reputation > (SELECT AVG(Reputation) FROM Users)  
ORDER BY UDS.Reputation DESC, UDS.PostCount ASC;