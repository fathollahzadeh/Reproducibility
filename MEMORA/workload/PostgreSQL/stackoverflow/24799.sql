
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN p.LastActivityDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') THEN 1 ELSE 0 END), 0) AS RecentActivity
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.Score > 0 AND p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month')
),
PostStatistics AS (
    SELECT 
        p.Id,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBounty,
        MAX(v.VoteTypeId) AS MaxVoteType
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
),
MergedData AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalAnswers,
        ua.TotalQuestions,
        ua.RecentActivity,
        ps.CommentCount,
        ps.AvgBounty,
        ps.MaxVoteType
    FROM 
        UserActivity ua
    LEFT JOIN 
        PostStatistics ps ON ua.UserId = ps.OwnerUserId
)
SELECT 
    md.DisplayName,
    md.TotalPosts,
    md.TotalAnswers,
    md.TotalQuestions,
    CASE 
        WHEN md.RecentActivity > 0 THEN 'Active User'
        ELSE 'Inactive User'
    END AS UserStatus,
    COALESCE(bp.Title, 'N/A') AS TopPostTitle,
    COALESCE(bp.Score, 0) AS TopPostScore,
    md.CommentCount,
    md.AvgBounty,
    CASE 
        WHEN md.MaxVoteType IS NULL THEN 'No Votes'
        WHEN md.MaxVoteType = 2 THEN 'Upvoted'
        WHEN md.MaxVoteType = 3 THEN 'Downvoted'
        ELSE 'Other Vote Activity'
    END AS MostRecentVoteStatus
FROM 
    MergedData md
LEFT JOIN 
    TopPosts bp ON md.TotalPosts = (SELECT MAX(TotalPosts) FROM MergedData) 
WHERE 
    md.TotalPosts > 0
ORDER BY 
    md.TotalPosts DESC,
    md.TotalAnswers DESC
FETCH FIRST 50 ROWS ONLY;
