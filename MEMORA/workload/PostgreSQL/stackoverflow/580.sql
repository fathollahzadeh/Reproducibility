
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
        AND P.PostTypeId IN (1, 2) 
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        CreationDate, 
        Owner,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostStats AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.Score,
        TP.Owner,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        TopPosts TP
    LEFT JOIN 
        Comments C ON TP.PostId = C.PostId
    LEFT JOIN 
        Votes V ON TP.PostId = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        TP.PostId, TP.Title, TP.Score, TP.Owner
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.Owner,
    PS.CommentCount,
    PS.TotalBounty,
    CASE 
        WHEN PS.Score >= 100 THEN 'High-Quality'
        WHEN PS.Score >= 50 THEN 'Moderate'
        ELSE 'Low-Quality'
    END AS QualityFlag,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PS.PostId AND V.VoteTypeId = 2) AS Upvotes,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PS.PostId AND V.VoteTypeId = 3) AS Downvotes
FROM 
    PostStats PS
ORDER BY 
    PS.Score DESC, PS.PostId DESC;
