
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.ID) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.DisplayName
),
PostHistoryAnalysis AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS RevisionCount,
        MAX(PH.CreationDate) AS LastEdited
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.OwnerDisplayName,
    PS.CommentCount,
    PS.TotalBounty,
    COALESCE(PHA.RevisionCount, 0) AS RevisionCount,
    PHA.LastEdited
FROM 
    PostStats PS
LEFT JOIN 
    PostHistoryAnalysis PHA ON PS.PostId = PHA.PostId
ORDER BY 
    PS.ViewCount DESC, PS.Score DESC
LIMIT 100;
