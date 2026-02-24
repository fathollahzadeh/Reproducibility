WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM Posts p
    WHERE p.PostTypeId = 1
),
UserVotes AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE -1 END) AS VoteScore
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
),
RecentActivity AS (
    SELECT
        p.Id,
        COUNT(c.Id) AS CommentCount,
        MAX(p.LastActivityDate) AS LastActive
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 MONTH'
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT DISTINCT
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
)
SELECT
    p.Id AS PostId,
    p.Title,
    COALESCE(rp.UserRank, 0) AS RankByScore,
    COALESCE(uv.VoteScore, 0) AS TotalVotes,
    ra.CommentCount,
    ra.LastActive,
    cp.CloseReason
FROM Posts p
LEFT JOIN RankedPosts rp ON rp.Id = p.Id
LEFT JOIN UserVotes uv ON uv.PostId = p.Id
LEFT JOIN RecentActivity ra ON ra.Id = p.Id
LEFT JOIN ClosedPosts cp ON cp.PostId = p.Id
WHERE 
    p.Score > 0 
    OR (p.AcceptedAnswerId IS NOT NULL AND p.PostTypeId = 1)
    AND (p.CreationDate BETWEEN cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 MONTHS' AND cast('2024-10-01 12:34:56' as timestamp))
ORDER BY 
    COALESCE(rp.UserRank, 0) ASC,
    TOTALVOTES DESC,
    ra.LastActive DESC;