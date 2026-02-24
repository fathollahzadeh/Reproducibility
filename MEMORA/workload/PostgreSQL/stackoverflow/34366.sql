WITH RECURSIVE ActiveUsers AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation,
        CreationDate,
        LastAccessDate,
        Rank() OVER (ORDER BY Reputation DESC) as UserRank
    FROM Users 
    WHERE Reputation > 1000
),
PostsWithScores AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(P.Score, 0) AS PostScore,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY P.Id, P.Title, P.Score, P.OwnerUserId
),
TopPosts AS (
    SELECT 
        PWS.PostId,
        PWS.Title,
        PWS.PostScore,
        PWS.CommentCount,
        PWS.TotalBounty,
        AU.DisplayName AS OwnerName,
        AU.Reputation AS OwnerReputation,
        DENSE_RANK() OVER (ORDER BY (PWS.PostScore + PWS.TotalBounty) DESC) AS Rank
    FROM PostsWithScores PWS
    JOIN ActiveUsers AU ON PWS.OwnerUserId = AU.Id
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        PH.CreationDate,
        PH.Comment AS CloseReason,
        P.Title,
        RANK() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS RecentClose
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId = 10 
)
SELECT 
    TP.Title,
    TP.PostScore,
    TP.CommentCount,
    TP.TotalBounty,
    TP.OwnerName,
    TP.OwnerReputation,
    COALESCE(CP.CloseReason, 'Not Closed') AS LastCloseReason
FROM TopPosts TP
LEFT JOIN ClosedPosts CP ON TP.PostId = CP.PostId AND CP.RecentClose = 1
WHERE TP.Rank <= 10 
ORDER BY TP.PostScore DESC;