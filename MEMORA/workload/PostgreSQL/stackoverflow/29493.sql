WITH PostTagStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        STRING_AGG(DISTINCT substring(tag.TagName from 1 for 20), ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT co.Id) AS ClosedPostCount
    FROM 
        Posts p
    LEFT JOIN 
        Tags tag ON p.Tags LIKE '%' || tag.TagName || '%'
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        Posts co ON co.Id = ph.PostId AND ph.Comment IS NOT NULL
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostMetrics AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Tags,
        p.CommentCount,
        ps.TotalPosts,
        ps.BadgeCount,
        ps.TotalViews,
        RANK() OVER (ORDER BY p.CommentCount DESC) AS CommentRank,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CommentCount DESC) AS TagRank
    FROM 
        PostTagStats p
    JOIN 
        UserStats ps ON p.OwnerUserId = ps.UserId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.Tags,
    pm.CommentCount,
    pm.TotalPosts,
    pm.BadgeCount,
    pm.TotalViews,
    pm.CommentRank,
    pm.TagRank
FROM 
    PostMetrics pm
WHERE 
    pm.CommentRank <= 10  
ORDER BY 
    pm.CommentCount DESC;