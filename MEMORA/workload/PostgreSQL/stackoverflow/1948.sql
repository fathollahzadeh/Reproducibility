WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
CommentsSummary AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN c.Score < 0 THEN 1 ELSE 0 END) AS NegativeComments
    FROM Comments c
    GROUP BY c.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    u.DisplayName,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    cs.TotalComments,
    cs.NegativeComments
FROM RankedPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN CommentsSummary cs ON rp.Id = cs.PostId
WHERE rp.rn = 1
  AND rp.Score > (
      SELECT AVG(Score) 
      FROM Posts 
      WHERE PostTypeId = 1
  )
ORDER BY rp.CreationDate DESC
LIMIT 10;
