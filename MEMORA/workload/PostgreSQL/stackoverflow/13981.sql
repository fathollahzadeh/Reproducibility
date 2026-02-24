
WITH PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, U.DisplayName
    ORDER BY 
        P.Score DESC, P.ViewCount DESC
    LIMIT 100  
)

SELECT 
    PP.PostId,
    PP.Title,
    PP.Score,
    PP.ViewCount,
    PP.OwnerDisplayName,
    PP.CommentCount
FROM 
    PopularPosts PP;
