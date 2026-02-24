
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        RANK() OVER (ORDER BY SUM(b.Class) DESC) AS BadgeRank
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        tu.BadgeRank
    FROM RecentPosts rp
    JOIN TopUsers tu ON rp.OwnerDisplayName = tu.DisplayName
    WHERE rp.PostRank <= 5
)

SELECT
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    CASE 
        WHEN fp.BadgeRank IS NULL THEN 'No Badges'
        ELSE CONCAT('Rank: ', fp.BadgeRank)
    END AS UserBadgeRank
FROM FilteredPosts fp
LEFT JOIN PostHistory ph ON fp.PostId = ph.PostId AND ph.CreationDate = (
    SELECT MAX(ph2.CreationDate)
    FROM PostHistory ph2
    WHERE ph2.PostId = fp.PostId
)
WHERE ph.PostHistoryTypeId IN (10, 12) 
  AND (fp.UpVotes - fp.DownVotes) > 10
ORDER BY fp.CreationDate DESC
LIMIT 100;
