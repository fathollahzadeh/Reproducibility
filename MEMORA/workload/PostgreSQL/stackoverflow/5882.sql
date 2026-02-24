WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.UserId) FILTER (WHERE V.VoteTypeId IN (2, 3)) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' AND 
        P.ViewCount > 100
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.CreationDate, P.Score, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        CreationDate,
        Score,
        OwnerName,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    TP.*,
    PHT.Name AS PostHistoryType,
    COUNT(PH.Id) AS HistoryCount
FROM 
    TopPosts TP
LEFT JOIN 
    PostHistory PH ON TP.PostId = PH.PostId
LEFT JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
GROUP BY 
    TP.PostId, TP.Title, TP.ViewCount, TP.CreationDate, TP.Score, TP.OwnerName, 
    TP.CommentCount, TP.VoteCount, PHT.Name
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;