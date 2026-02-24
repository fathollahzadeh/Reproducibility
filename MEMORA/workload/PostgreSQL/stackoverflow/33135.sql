WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS UpvoteCount,
        MAX(ph.Level) AS MaxLevel
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    LEFT JOIN 
        PostHierarchy ph ON p.Id = ph.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title, p.Score
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.CommentCount,
        pd.UpvoteCount,
        ub.BadgeCount,
        ub.Badges
    FROM 
        PostDetails pd
    JOIN 
        UserBadges ub ON pd.PostId IN (SELECT ParentId FROM Posts WHERE OwnerUserId = ub.UserId)
    WHERE 
        pd.UpvoteCount > 5  
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.BadgeCount,
    tp.Badges,
    CASE 
        WHEN tp.BadgeCount >= 10 THEN 'Expert' 
        WHEN tp.BadgeCount BETWEEN 5 AND 9 THEN 'Contributor'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC
LIMIT 100;