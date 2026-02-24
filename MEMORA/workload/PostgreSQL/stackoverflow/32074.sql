
WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        0 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL

    UNION ALL

    SELECT 
        U.Id,
        U.Reputation,
        U.CreationDate,
        CTE.Level + 1
    FROM 
        UserReputationCTE CTE
    JOIN 
        Users U ON U.Id = CTE.UserId
    WHERE 
        CTE.Level < 3
),
AverageVotes AS (
    SELECT 
        P.OwnerUserId,
        AVG(VoteTypeId) AS AvgVote
    FROM 
        Posts P
    JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.OwnerUserId
),
PostWithHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        P.Title,
        P.Score,
        P.ViewCount,
        U.Reputation AS UserReputation,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = PH.PostId) AS CommentCount,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RN
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        PH.CreationDate >= '2023-01-01 00:00:00'
),
FilteredPosts AS (
    SELECT 
        P.Id,
        P.Title,
        COALESCE(AvgVote, 0) AS AverageVote,
        P.ViewCount,
        P.Score,
        U.Id AS UserId,
        U.DisplayName,
        (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = P.Id AND PH.PostHistoryTypeId = 10) AS CloseCount
    FROM 
        Posts P
    LEFT JOIN 
        AverageVotes AV ON P.OwnerUserId = AV.OwnerUserId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= '2023-01-01 00:00:00'
        AND (P.Score > 10 OR P.ViewCount > 100)
)

SELECT 
    FP.Title,
    FP.AverageVote,
    FP.ViewCount,
    FP.Score,
    PWH.CreationDate AS LastEditDate,
    PWH.Comment,
    U.DisplayName AS PostOwner,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = FP.UserId) AS BadgeCount
FROM 
    FilteredPosts FP
LEFT JOIN 
    PostWithHistory PWH ON FP.Id = PWH.PostId AND PWH.RN = 1
JOIN 
    Users U ON FP.UserId = U.Id
WHERE 
    FP.CloseCount = 0
ORDER BY 
    FP.AverageVote DESC, FP.Score DESC
LIMIT 10;
