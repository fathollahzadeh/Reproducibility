WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.Score > 0
    GROUP BY P.Id, P.Title, U.DisplayName, P.ViewCount, P.Score, P.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CommentCount,
        ViewCount,
        Score
    FROM RankedPosts
    WHERE Rank <= 10
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
)
SELECT 
    TP.Title,
    TP.OwnerDisplayName,
    TP.CommentCount,
    TP.ViewCount,
    TP.Score,
    COALESCE(BC.BadgeCount, 0) AS UserBadgeCount
FROM TopPosts TP
LEFT JOIN BadgeCounts BC ON TP.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = BC.UserId)
ORDER BY TP.Score DESC, TP.ViewCount DESC;
