
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(TH.TagCount, 0) AS TagCount
    FROM Posts p
    LEFT JOIN (
        SELECT 
            Id,
            (SELECT COUNT(*) FROM UNNEST(STRING_TO_ARRAY(Tags, '><')) AS tag_table) AS TagCount
        FROM Posts 
        WHERE Tags IS NOT NULL
    ) TH ON p.Id = TH.Id
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS BadgePoints,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE u.LastAccessDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(*) AS CloseCount
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.Rank,
    au.UserId,
    au.DisplayName,
    au.BadgePoints,
    au.PostCount,
    au.UpVotes,
    COALESCE(cp.CloseCount, 0) AS CloseCount
FROM RankedPosts rp
JOIN ActiveUsers au ON rp.PostId = au.PostCount
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    (rp.Score > 0 AND au.BadgePoints > 1)
    OR (rp.TagCount > 5 AND COALESCE(cp.CloseCount, 0) = 0)
ORDER BY rp.Score DESC, au.BadgePoints DESC
LIMIT 100 OFFSET 0;
