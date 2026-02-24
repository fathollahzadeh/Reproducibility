WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(A.Id) AS TotalAnswers,
        AVG(V.BountyAmount) AS AverageBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.PostTypeId
)
SELECT 
    PST.PostId,
    PST.Title,
    PST.PostTypeId,
    PST.CreationDate,
    PST.ViewCount,
    PST.Score,
    PST.TotalComments,
    PST.TotalAnswers,
    PST.AverageBounty
FROM 
    PostStats PST
ORDER BY 
    PST.ViewCount DESC
LIMIT 100;