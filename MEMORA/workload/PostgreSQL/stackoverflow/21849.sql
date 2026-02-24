
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 
      AND p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.PostId END) AS ClosedQuestions,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.PostId END) AS ReopenedQuestions,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpvotesReceived
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
FilteredPosts AS (
    SELECT rp.*,
           us.Reputation,
           us.GoldBadges,
           us.SilverBadges,
           us.BronzeBadges,
           CASE 
               WHEN us.Reputation > 1000 THEN 'Experienced'
               WHEN us.Reputation BETWEEN 500 AND 1000 THEN 'Moderate'
               ELSE 'Novice'
           END AS UserExperienceLevel
    FROM RankedPosts rp
    JOIN UserStats us ON rp.OwnerUserId = us.UserId
    WHERE rp.UserPostRank <= 3
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.Reputation,
    fp.UserExperienceLevel,
    COALESCE(SUM(CASE WHEN ph.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalEdits,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = fp.PostId) AS CommentCount
FROM FilteredPosts fp
LEFT JOIN PostHistory ph ON fp.PostId = ph.PostId
GROUP BY fp.PostId, fp.Title, fp.CreationDate, fp.Score, fp.ViewCount, fp.Reputation, fp.UserExperienceLevel
ORDER BY fp.Score DESC, fp.ViewCount DESC
LIMIT 10;
