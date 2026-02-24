WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        COUNT(DISTINCT v.PostId) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
RecentClosePosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    u.DisplayName AS UserName,
    r.PostRank,
    COALESCE(uvs.TotalVotes, 0) AS UserTotalVotes,
    COALESCE(uvs.UpVotes, 0) AS UserUpVotes,
    COALESCE(uvs.DownVotes, 0) AS UserDownVotes,
    c.FirstCloseDate
FROM 
    RankedPosts r
JOIN 
    Posts p ON r.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserVoteStats uvs ON u.Id = uvs.UserId
LEFT JOIN 
    RecentClosePosts c ON p.Id = c.PostId
WHERE 
    r.PostRank <= 10
    AND (p.ViewCount > 100 OR p.Score > 5)
ORDER BY 
    p.CreationDate DESC
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;