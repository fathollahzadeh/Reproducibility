
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
        MAX(p.CreationDate) AS LastPostDate,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.Score, p.ViewCount, p.CreationDate, p.LastActivityDate
),
BenchmarkingResults AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalQuestions,
        ua.TotalAnswers,
        ua.TotalComments,
        ua.TotalVotes,
        ua.TotalBadges,
        ua.LastPostDate,
        ua.LastActivityDate,
        COUNT(ps.PostId) AS TotalPostStats,
        AVG(ps.Score) AS AveragePostScore,
        AVG(ps.ViewCount) AS AveragePostViewCount,
        SUM(ps.UpVotes) AS TotalUpVotes,
        SUM(ps.DownVotes) AS TotalDownVotes
    FROM 
        UserActivity ua
    LEFT JOIN 
        PostStats ps ON ua.UserId = ps.PostId  
    GROUP BY 
        ua.UserId, ua.DisplayName, 
        ua.TotalPosts, ua.TotalQuestions, 
        ua.TotalAnswers, ua.TotalComments, 
        ua.TotalVotes, ua.TotalBadges, 
        ua.LastPostDate, ua.LastActivityDate
)
SELECT 
    *
FROM 
    BenchmarkingResults
ORDER BY 
    TotalPosts DESC;
