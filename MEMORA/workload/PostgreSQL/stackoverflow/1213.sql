
WITH UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(CASE WHEN ub.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN ub.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN ub.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges ub
    GROUP BY ub.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Score,
        rp.CommentCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS PostRank
    FROM RecentPosts rp
    JOIN Users u ON rp.OwnerUserId = u.Id
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    tp.PostId,
    tp.Title AS PostTitle,
    tp.CreationDate AS PostCreationDate,
    tp.Score AS PostScore,
    tp.CommentCount AS PostCommentCount
FROM TopUsers tu
LEFT JOIN TopPosts tp ON tu.UserId = tp.OwnerUserId
WHERE tu.Rank <= 10 AND (tp.PostRank IS NULL OR tp.PostRank <= 5)
ORDER BY tu.Reputation DESC, tp.Score DESC;
