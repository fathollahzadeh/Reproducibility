
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalPostViews,
        SUM(pm.ViewCount) AS PostMetricsViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostMetrics pm ON p.Id = pm.PostId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
)
SELECT 
    um.UserId,
    um.DisplayName,
    um.Reputation,
    um.BadgeCount,
    um.TotalPostViews,
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.ViewCount,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes
FROM 
    UserMetrics um
JOIN 
    PostMetrics pm ON um.UserId = pm.PostId
ORDER BY 
    um.Reputation DESC, pm.ViewCount DESC
LIMIT 100;
