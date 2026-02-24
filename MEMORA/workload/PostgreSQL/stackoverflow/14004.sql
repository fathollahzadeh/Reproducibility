
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id AND A.PostTypeId = 2
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    GROUP BY 
        P.Id, P.PostTypeId, P.Title, P.CreationDate, P.Score, P.ViewCount
)
SELECT 
    PST.PostId,
    PST.Title,
    PST.CreationDate,
    PST.PostTypeId,
    PST.Score,
    PST.ViewCount,
    PST.CommentCount,
    PST.AnswerCount,
    PST.TotalBounty,
    U.Reputation,
    U.DisplayName AS OwnerDisplayName
FROM 
    PostStats PST
JOIN 
    Users U ON PST.PostTypeId = 1 AND PST.PostId = U.AccountId 
ORDER BY 
    PST.Score DESC,
    PST.ViewCount DESC
LIMIT 100;
