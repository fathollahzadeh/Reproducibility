
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1    
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        COALESCE(ph.Level, 0) AS HierarchyLevel,
        COALESCE(ue.VoteCount, 0) AS UserEngagementCount,
        COALESCE(ue.UpVotes, 0) AS UpVoteCount,
        COALESCE(ue.DownVotes, 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHierarchy ph ON p.Id = ph.PostId
    LEFT JOIN 
        UserEngagement ue ON p.OwnerUserId = ue.UserId
),
UserPostEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(ps.PostId) AS TotalPosts,
        SUM(CASE WHEN ps.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN ps.Score <= 0 THEN 1 ELSE 0 END) AS NonPositivePosts,
        AVG(ps.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.DisplayName,
    up.TotalPosts,
    up.PositivePosts,
    up.NonPositivePosts,
    up.AverageScore,
    SUM(ps.UserEngagementCount) AS TotalEngagement,
    SUM(ps.UpVoteCount) AS TotalUpVotes,
    SUM(ps.DownVoteCount) AS TotalDownVotes,
    MAX(ps.CreationDate) AS LatestPostDate
FROM 
    UserPostEngagement up
JOIN 
    PostStats ps ON up.UserId = ps.OwnerUserId
JOIN 
    Users u ON u.Id = up.UserId
GROUP BY 
    u.DisplayName, up.TotalPosts, up.PositivePosts, up.NonPositivePosts, up.AverageScore
HAVING 
    SUM(ps.Score) > 0                             
ORDER BY 
    TotalEngagement DESC
LIMIT 10;
