
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN LATERAL unnest(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS t(TagName) ON TRUE
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        RP.CommentCount,
        RP.Tags
    FROM RankedPosts RP
    WHERE RP.PostRank = 1 
    ORDER BY RP.Score DESC, RP.ViewCount DESC
    LIMIT 10
),
PostMetrics AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.CreationDate,
        TP.Score,
        TP.ViewCount,
        TP.OwnerDisplayName,
        TP.CommentCount,
        TP.Tags,
        COALESCE(BadgeCount.Gold, 0) AS GoldBadges,
        COALESCE(BadgeCount.Silver, 0) AS SilverBadges,
        COALESCE(BadgeCount.Bronze, 0) AS BronzeBadges
    FROM TopPosts TP
    LEFT JOIN (
        SELECT 
            UserId,
            SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS Gold,
            SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS Silver,
            SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS Bronze
        FROM Badges
        GROUP BY UserId
    ) BadgeCount ON TP.OwnerDisplayName = (
        SELECT DisplayName 
        FROM Users 
        WHERE Id = BadgeCount.UserId
        LIMIT 1
    )
)
SELECT 
    PM.*,
    (SELECT COUNT(*) FROM Votes WHERE PostId = PM.PostId) AS VoteCount,
    (SELECT COUNT(*) FROM PostHistory WHERE PostId = PM.PostId AND PostHistoryTypeId IN (10, 11)) AS CloseReopenCount
FROM PostMetrics PM
ORDER BY PM.Score DESC, PM.ViewCount DESC;
