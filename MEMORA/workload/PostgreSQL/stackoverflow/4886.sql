
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        NTILE(4) OVER (ORDER BY Reputation DESC) AS ReputationQuartile
    FROM Users
),
TopQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        COALESCE(AVG(V.BountyAmount), 0) AS AvgBounty
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8
    WHERE P.PostTypeId = 1 
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, U.DisplayName
    HAVING COUNT(C.Id) >= 5 AND AVG(V.BountyAmount) > 0
    ORDER BY P.Score DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    TQ.PostId,
    TQ.Title,
    TQ.CreationDate,
    TQ.Score,
    TQ.OwnerDisplayName,
    TQ.CommentCount,
    TQ.AvgBounty,
    UP.ReputationQuartile,
    UB.BadgeCount,
    UB.BadgeNames
FROM TopQuestions TQ
JOIN UserReputation UP ON UP.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = TQ.PostId LIMIT 1)
LEFT JOIN UserBadges UB ON UB.UserId = UP.UserId
ORDER BY TQ.Score DESC, TQ.CommentCount DESC;
