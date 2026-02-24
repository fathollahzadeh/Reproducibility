
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        ph.Level + 1 AS Level
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COUNT(DISTINCT b.Id) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        MAX(re.CreationDate) AS LastEditDate,
        COUNT(DISTINCT CASE WHEN b.Id IS NOT NULL THEN b.Id END) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        RecentEdits re ON p.Id = re.PostId AND re.rn = 1
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    ph.Id AS QuestionId,
    ph.Title AS QuestionTitle,
    u.DisplayName AS OwnerName,
    us.Upvotes,
    us.Downvotes,
    pm.CommentCount,
    pm.TotalUpvotes,
    pm.TotalDownvotes,
    pm.LastEditDate,
    pm.BadgeCount,
    (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = ph.Id) AS RelatedLinkCount
FROM 
    PostHierarchy ph
JOIN 
    Users u ON ph.OwnerUserId = u.Id
JOIN 
    UserStats us ON us.UserId = u.Id
JOIN 
    PostMetrics pm ON pm.PostId = ph.Id
WHERE 
    ph.Level = 0  
ORDER BY 
    pm.TotalUpvotes DESC, pm.CommentCount DESC;
