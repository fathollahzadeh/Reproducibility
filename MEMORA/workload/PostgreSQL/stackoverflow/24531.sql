WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(vote.Upvotes, 0) AS Upvotes,
        COALESCE(vote.Downvotes, 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            PostId,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes
         FROM 
            Votes 
         GROUP BY PostId) AS vote ON vote.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    WHERE 
        p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, vote.Upvotes, vote.Downvotes
),
PostStatistics AS (
    SELECT 
        rp.OwnerUserId, 
        COUNT(rp.PostId) AS TotalPosts,
        SUM(rp.Upvotes) AS TotalUpvotes,
        SUM(rp.Downvotes) AS TotalDownvotes,
        MAX(rp.CommentCount) AS MaxComments,
        AVG(rp.CloseCount) AS AvgCloseCount,
        AVG(rp.ReopenCount) AS AvgReopenCount
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ps.TotalPosts,
    ps.TotalUpvotes,
    ps.TotalDownvotes,
    ps.MaxComments,
    ps.AvgCloseCount,
    ps.AvgReopenCount,
    CASE 
        WHEN ps.TotalPosts IS NULL THEN 'No Posts'
        ELSE 'Active Contributor'
    END AS ContributionStatus
FROM 
    Users u
LEFT JOIN 
    PostStatistics ps ON u.Id = ps.OwnerUserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    ps.TotalUpvotes DESC NULLS LAST,
    ps.TotalPosts DESC NULLS LAST;