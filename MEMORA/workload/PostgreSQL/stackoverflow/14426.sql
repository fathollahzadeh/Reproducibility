
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS Author,
        COUNT(C.ID) AS CommentCount,
        COUNT(V.ID) AS VoteCount,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.Author,
    RP.CommentCount,
    RP.VoteCount
FROM 
    RankedPosts RP
WHERE 
    RP.Rank <= 100  
ORDER BY 
    RP.CreationDate DESC;
