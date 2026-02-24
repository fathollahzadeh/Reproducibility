
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        EXTRACT(YEAR FROM AGE(u.CreationDate)) AS AccountAge,
        CASE 
            WHEN COUNT(DISTINCT p.Id) > 10 THEN 'High Contributor'
            WHEN COUNT(DISTINCT p.Id) BETWEEN 5 AND 10 THEN 'Moderate Contributor'
            ELSE 'Low Contributor' 
        END AS ContributorLevel
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT p2.Id) AS LinkedPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Posts p2 ON pl.RelatedPostId = p2.Id
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.BadgeCount,
    us.TotalViews,
    us.TotalUpvotes,
    us.TotalDownvotes,
    us.AccountAge,
    us.ContributorLevel,
    ps.Title AS PostTitle,
    ps.PostType,
    ps.CommentCount,
    ps.LinkedPosts,
    ps.TotalUpvotes AS PostUpvotes,
    ps.TotalDownvotes AS PostDownvotes
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.UserId = ps.PostId
ORDER BY 
    us.Reputation DESC, ps.TotalUpvotes DESC
LIMIT 100;
