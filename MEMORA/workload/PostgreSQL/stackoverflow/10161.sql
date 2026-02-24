WITH UserPostDetails AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.Reputation, P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
UserBadgeCount AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    UPD.UserId,
    UPD.Reputation,
    UPD.PostId,
    UPD.Title,
    UPD.PostCreationDate,
    UPD.ViewCount,
    UPD.Score,
    UPD.CommentCount,
    COALESCE(UBC.BadgeCount, 0) AS BadgeCount
FROM 
    UserPostDetails UPD
LEFT JOIN 
    UserBadgeCount UBC ON UPD.UserId = UBC.UserId
ORDER BY 
    UPD.Reputation DESC, 
    UPD.ViewCount DESC;