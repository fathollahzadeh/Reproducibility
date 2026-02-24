
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgesCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.PostId END) AS ClosedPostsCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
), UserRanked AS (
    SELECT 
        ua.*,
        RANK() OVER (ORDER BY (Upvotes - Downvotes) DESC, PostCount DESC) AS ActivityRank
    FROM 
        UserActivity ua
), FilteredUsers AS (
    SELECT 
        r.UserId,
        r.DisplayName,
        r.Upvotes,
        r.Downvotes,
        r.PostCount,
        r.CommentCount,
        r.BadgesCount,
        r.ClosedPostsCount,
        r.ActivityRank
    FROM 
        UserRanked r
    WHERE 
        r.PostCount > 5 AND 
        r.BadgesCount > 2
), TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        ROW_NUMBER() OVER (ORDER BY (COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0)) DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title
    HAVING 
        COUNT(c.Id) > 10
)
SELECT 
    fu.DisplayName,
    fu.Upvotes,
    fu.Downvotes,
    fu.PostCount,
    fu.CommentCount,
    p.Title AS PopularPostTitle,
    p.TotalComments,
    p.TotalUpvotes,
    p.TotalDownvotes,
    fu.ActivityRank
FROM 
    FilteredUsers fu
JOIN 
    TopPosts p ON fu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = p.PostId)
WHERE 
    fu.ActivityRank <= 10 
    AND (fu.ClosedPostsCount IS NULL OR fu.ClosedPostsCount = 0)
ORDER BY 
    fu.ActivityRank;
