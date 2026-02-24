
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT b.Id) AS BadgesCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(a.OwnerDisplayName, 'Community User') AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id
    WHERE p.PostTypeId = 1  
), 
FilteredPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.OwnerDisplayName,
        pd.CommentCount
    FROM PostDetails pd
    WHERE pd.RN <= 5  
)
SELECT 
    us.DisplayName AS UserDisplayName,
    us.Upvotes,
    us.Downvotes,
    COUNT(DISTINCT fp.PostId) AS TotalPosts,
    SUM(fp.ViewCount) AS TotalViews,
    MAX(fp.CreationDate) AS LastActivePostDate
FROM UserStatistics us
LEFT JOIN FilteredPosts fp ON us.DisplayName = fp.OwnerDisplayName
GROUP BY us.UserId, us.DisplayName, us.Upvotes, us.Downvotes
ORDER BY TotalPosts DESC, UserDisplayName;
