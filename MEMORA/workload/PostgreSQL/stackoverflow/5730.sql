
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS DeletionVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END), 0) AS AcceptedVotes,
        pt.Name AS PostType,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tags_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tags_array
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year') 
    GROUP BY 
        p.Id, pt.Name
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(b.Class, 0)) AS BadgeScore,
        SUM(COALESCE(BadgeCount.BadgeCount, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) AS BadgeCount ON u.Id = BadgeCount.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.PostType,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.DeletionVotes,
    pm.AcceptedVotes,
    ue.DisplayName AS CreatorName,
    ue.PostsCreated,
    ue.BadgeScore,
    ue.TotalBadges,
    pm.Tags
FROM 
    PostMetrics pm
JOIN 
    UserEngagement ue ON pm.PostId = ue.UserId
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC
LIMIT 100;
