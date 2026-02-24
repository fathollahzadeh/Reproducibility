
WITH RECURSIVE UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
PostScore AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        COALESCE(MAX(b.Class), 0) AS MaxBadgeClass 
    FROM Posts p
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY p.Id, p.OwnerUserId, p.Score
),
PostWithUserStats AS (
    SELECT 
        p.*,
        COALESCE(u.Reputation, 0) AS UserReputation,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
),
RankedPosts AS (
    SELECT 
        pwus.*,
        RANK() OVER (PARTITION BY pwus.PostTypeId ORDER BY pwus.Score DESC, pwus.ViewCount DESC) AS PostRank
    FROM PostWithUserStats pwus
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UserReputation,
    rp.UserBadgeCount,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AnswerStatus,
    STRING_AGG(DISTINCT tag.TagName, ', ') AS TagsList
FROM RankedPosts rp
LEFT JOIN LATERAL (
    SELECT 
        unnest(string_to_array(rp.Tags, '>,<')) AS TagName
) AS tag ON TRUE
WHERE rp.PostRank <= 10 
GROUP BY 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UserReputation,
    rp.UserBadgeCount,
    rp.AcceptedAnswerId,
    rp.PostTypeId
ORDER BY 
    rp.PostTypeId, rp.Score DESC;
