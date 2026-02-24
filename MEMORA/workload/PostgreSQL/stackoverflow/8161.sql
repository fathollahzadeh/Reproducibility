
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.CreationDate, U.DisplayName
),
TopPosts AS (
    SELECT 
        RP.*,
        (Upvotes - Downvotes) AS Score,
        RANK() OVER (ORDER BY (Upvotes - Downvotes) DESC, ViewCount DESC) AS ScoreRank
    FROM 
        RankedPosts RP
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.OwnerDisplayName,
    TP.ViewCount,
    TP.Upvotes,
    TP.Downvotes,
    TP.CommentCount,
    TP.Score,
    TP.ScoreRank,
    CASE 
        WHEN TP.ScoreRank <= 10 THEN 'Top 10 Post'
        ELSE 'Not Ranked Top 10'
    END AS PostCategory
FROM 
    TopPosts TP
WHERE 
    TP.PostRank <= 50
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;
