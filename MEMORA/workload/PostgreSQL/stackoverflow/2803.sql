
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
UserMetrics AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        AVG(p.Score) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.UserDisplayName
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    um.DisplayName AS OwnerDisplayName,
    um.UpVoteCount,
    um.DownVoteCount,
    um.BadgeCount,
    um.AvgPostScore,
    cp.CloseCount,
    COALESCE(cp.CloseCount, 0) AS CloseCountNullable
FROM 
    RecentPosts rp
JOIN 
    UserMetrics um ON rp.OwnerUserId = um.UserID
LEFT JOIN 
    ClosedPosts cp ON rp.PostID = cp.PostId
WHERE 
    um.AvgPostScore > 10
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
