
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        ph.Comment, 
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.LastActivityDate,
        COALESCE(ph.Comment, 'No close reason') AS CloseReason,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
),
UserScores AS (
    SELECT 
        ue.UserId,
        ue.TotalUpVotes,
        ue.TotalDownVotes,
        ue.TotalComments,
        ue.TotalPosts,
        ue.AvgViews,
        ue.AvgScore,
        ROW_NUMBER() OVER (ORDER BY ue.TotalUpVotes - ue.TotalDownVotes DESC) AS EngagementRank
    FROM 
        UserEngagement ue
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.LastActivityDate,
    ps.CloseReason,
    us.UserId,
    us.TotalPosts,
    us.TotalComments,
    us.AvgViews,
    us.AvgScore,
    ps.Rank,
    us.EngagementRank
FROM 
    PostStatistics ps
JOIN 
    Posts p ON ps.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserScores us ON us.UserId = u.Id
WHERE 
    ps.Rank <= 10 
    AND us.EngagementRank <= 10 
ORDER BY 
    ps.Rank, us.EngagementRank;
