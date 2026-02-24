WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(C.ID) AS CommentCount,
        COUNT(B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        P.Id
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.BadgeCount,
    PS.TotalBounty,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation
FROM 
    PostStats PS
JOIN 
    Users U ON PS.PostId IN (
        SELECT 
            Id 
        FROM 
            Posts 
        WHERE 
            OwnerUserId = U.Id
    )
ORDER BY 
    PS.Score DESC, 
    PS.ViewCount DESC
LIMIT 100;