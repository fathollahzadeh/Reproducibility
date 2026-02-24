
WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        (SELECT COUNT(*) FROM Badges WHERE UserId = U.Id) AS BadgeCount
    FROM 
        Users U
), 
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount
), 
PostDetails AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.Score,
        TP.ViewCount,
        TP.CommentCount,
        U.DisplayName,
        U.Reputation,
        COALESCE(UR.BadgeCount, 0) AS BadgeCount
    FROM 
        TopPosts TP
    LEFT JOIN 
        Users U ON U.Id = (SELECT AcceptedAnswerId FROM Posts WHERE Id = TP.PostId) 
    LEFT JOIN 
        UserReputation UR ON U.Id = UR.Id
)
SELECT 
    PD.Title,
    PD.Score,
    PD.ViewCount,
    PD.CommentCount,
    PD.DisplayName,
    PD.Reputation,
    PD.BadgeCount,
    RANK() OVER (ORDER BY PD.Score DESC) AS RankedByScore,
    ROW_NUMBER() OVER (ORDER BY PD.ViewCount DESC) AS RowByViews,
    CASE 
        WHEN PD.Reputation IS NULL THEN 'No Reputation' 
        WHEN PD.Reputation < 100 THEN 'Novice' 
        WHEN PD.Reputation BETWEEN 100 AND 500 THEN 'Intermediate'
        ELSE 'Expert' 
    END AS ReputationCategory
FROM 
    PostDetails PD
WHERE 
    PD.CommentCount > 0
ORDER BY 
    PD.Score DESC, PD.ViewCount DESC
LIMIT 20;
