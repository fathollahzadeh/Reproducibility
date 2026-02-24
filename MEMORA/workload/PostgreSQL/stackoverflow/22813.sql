WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.LastActivityDate,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.ViewCount > 100
), 

RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        DENSE_RANK() OVER (ORDER BY u.CreationDate DESC) AS RecentRank
    FROM Users u
    WHERE u.Reputation IS NOT NULL
),

VoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.LastActivityDate,
    rp.RankByViews,
    ru.DisplayName AS LatestUser,
    ru.Reputation,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus,
    CASE 
        WHEN rp.CreationDate < (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year') THEN 'Old'
        ELSE 'New'
    END AS PostAgeStatus
FROM RankedPosts rp
LEFT JOIN RecentUsers ru ON ru.RecentRank = 1
LEFT JOIN VoteSummary vs ON rp.PostId = vs.PostId
WHERE rp.RankByViews <= 5
ORDER BY rp.ViewCount DESC
LIMIT 10;