
WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        CASE 
            WHEN Reputation >= 1000 THEN 'High Rep' 
            WHEN Reputation < 1000 AND Reputation >= 100 THEN 'Medium Rep' 
            ELSE 'Low Rep' 
        END AS ReputationCategory
    FROM Users
),
PostStats AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.Score, 
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 END), 0) AS Downvotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        RANK() OVER (ORDER BY P.CreationDate DESC) AS RecentRank
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score
),
ClosedPosts AS (
    SELECT 
        PH.PostId, 
        PH.CreationDate, 
        P.Title AS ClosedTitle, 
        CRT.Name AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes CRT ON PH.Comment = CAST(CRT.Id AS VARCHAR)
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId = 10
)
SELECT 
    UR.UserId, 
    UR.Reputation, 
    UR.ReputationCategory,
    PS.PostId, 
    PS.Title, 
    PS.CreationDate, 
    PS.Score, 
    PS.Upvotes, 
    PS.Downvotes, 
    PS.CommentCount,
    CP.ClosedTitle,
    CP.CloseReason,
    DENSE_RANK() OVER (PARTITION BY UR.ReputationCategory ORDER BY PS.Score DESC) AS CategoryScoreRank,
    CASE 
        WHEN CP.ClosedTitle IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM UserReputation UR
JOIN Posts P ON UR.UserId = P.OwnerUserId
JOIN PostStats PS ON P.Id = PS.PostId
LEFT JOIN ClosedPosts CP ON P.Id = CP.PostId
WHERE UR.Reputation > 0 
    AND COALESCE(PS.Upvotes - PS.Downvotes, 0) > 5 
    AND PS.RecentRank <= 100 
ORDER BY UR.Reputation DESC, PS.Score DESC;
