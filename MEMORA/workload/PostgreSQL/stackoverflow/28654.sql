
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
MostActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COUNT(C.Id) AS TotalComments,
        RANK() OVER (ORDER BY COUNT(C.Id) DESC) AS CommentRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        P.ViewCount,
        CASE 
            WHEN P.Score > 0 THEN 'Positive'
            WHEN P.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS PostSentiment,
        P.CreationDate,
        SUM(V.BountyAmount) AS TotalBounty,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId, U.DisplayName, P.ViewCount, P.Score, P.CreationDate
)
SELECT 
    PU.ReputationRank,
    PU.DisplayName AS Poster,
    PS.Title AS PostTitle,
    PS.ViewCount,
    PS.PostSentiment,
    M.TotalComments,
    PS.TotalBounty,
    PS.CommentCount
FROM 
    PostStatistics PS
JOIN 
    RankedUsers PU ON PS.OwnerUserId = PU.UserId
JOIN 
    MostActivePosts M ON PS.PostId = M.PostId
WHERE 
    PS.ViewCount > 100
    AND PS.CommentCount > 0
ORDER BY 
    PU.ReputationRank ASC, M.TotalComments DESC;
