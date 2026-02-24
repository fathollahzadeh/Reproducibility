WITH RECURSIVE UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        V.VoteTypeId,
        COUNT(V.Id) AS VoteCount
    FROM 
        Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.Reputation, V.VoteTypeId
),
PostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.ViewCount, P.Score, P.AcceptedAnswerId
),
TopPosts AS (
    SELECT 
        PI.PostId,
        PI.Title,
        PI.ViewCount,
        PI.Score,
        PI.AcceptedAnswerId,
        PI.CommentCount,
        PI.TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY PI.AcceptedAnswerId ORDER BY PI.Score DESC) AS RowNum
    FROM 
        PostInfo PI
)
SELECT 
    U.DisplayName,
    U.Reputation,
    TP.Title,
    TP.ViewCount,
    TP.Score,
    TP.CommentCount,
    TP.TotalBounty
FROM 
    Users U
INNER JOIN Votes V ON U.Id = V.UserId
INNER JOIN TopPosts TP ON V.PostId = TP.PostId
WHERE 
    TP.RowNum = 1 
    AND U.Reputation > 1000
    AND (TP.TotalBounty IS NULL OR TP.TotalBounty > 0)
ORDER BY 
    U.Reputation DESC,
    TP.Score DESC;
