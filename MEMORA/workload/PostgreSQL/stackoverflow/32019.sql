
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
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
        p.Title,
        p.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.CreationDate AS HistoryDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
),
RecentActivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.LastActivityDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title
)

SELECT 
    ua.DisplayName,
    rp.Title AS TopPost,
    rp.Score AS TopScore,
    ua.UpVotes,
    ua.DownVotes,
    cp.Title AS ClosedPostTitle,
    cp.Comment AS CloseReason,
    cp.HistoryDate AS ClosedDate,
    ra.PostCount,
    ra.BadgeCount,
    rcp.CommentCount AS RecentCommentCount
FROM 
    UserEngagement ua
JOIN 
    RankedPosts rp ON rp.rn = 1
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.Id
LEFT JOIN 
    UserEngagement ra ON ra.UserId = ua.UserId 
LEFT JOIN 
    RecentActivePosts rcp ON rcp.Id = rp.Id
WHERE 
    ua.PostCount > 0
    AND (ua.UpVotes - ua.DownVotes) > 10
ORDER BY 
    ua.PostCount DESC, ua.BadgeCount DESC;
