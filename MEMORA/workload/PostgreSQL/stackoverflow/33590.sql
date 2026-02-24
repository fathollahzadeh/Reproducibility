WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        1 AS Level
    FROM Users U
    WHERE U.Reputation > 10000  
    UNION ALL
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        UR.Level + 1
    FROM Users U
    JOIN UserReputation UR ON U.Reputation > UR.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        COUNT(CASE WHEN Ph.Comment IS NOT NULL THEN 1 END) AS EditCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory Ph ON P.Id = Ph.PostId
    GROUP BY P.Id, P.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        PS.PostId,
        PS.OwnerUserId,
        PS.TotalBounty,
        PS.CommentCount,
        PS.VoteCount,
        PS.EditCount,
        U.Reputation AS OwnerReputation
    FROM PostStats PS
    JOIN Users U ON PS.OwnerUserId = U.Id
    WHERE PS.CommentCount > 5 AND PS.VoteCount > 10
),
RankedPosts AS (
    SELECT 
        FP.PostId,
        FP.OwnerUserId,
        FP.TotalBounty,
        FP.CommentCount,
        FP.VoteCount,
        FP.EditCount,
        FP.OwnerReputation,
        RANK() OVER (PARTITION BY FP.OwnerUserId ORDER BY FP.VoteCount DESC, FP.CommentCount DESC) AS Rank
    FROM FilteredPosts FP
)
SELECT 
    RP.PostId,
    U.DisplayName AS OwnerName,
    RP.TotalBounty,
    RP.CommentCount,
    RP.VoteCount,
    RP.EditCount,
    RP.Rank,
    COALESCE(T.TagName, 'No Tag') AS TopTag
FROM RankedPosts RP
JOIN Users U ON RP.OwnerUserId = U.Id
LEFT JOIN (
    SELECT 
        TL.PostId,
        T.TagName,
        ROW_NUMBER() OVER (PARTITION BY TL.PostId ORDER BY T.Count DESC) AS TagRank
    FROM PostLinks TL
    JOIN Tags T ON TL.RelatedPostId = T.Id
) T ON RP.PostId = T.PostId AND T.TagRank = 1
WHERE RP.Rank = 1  
ORDER BY RP.OwnerReputation DESC, RP.CommentCount DESC;