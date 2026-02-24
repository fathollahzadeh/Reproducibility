WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserActivityRanked AS (
    SELECT
        u.Id,
        u.DisplayName,
        us.Upvotes,
        us.Downvotes,
        us.TotalVotes,
        ps.TotalPosts,
        ps.TotalScore,
        ps.AvgViews,
        ps.TotalAnswers,
        RANK() OVER (ORDER BY COALESCE(ps.TotalPosts, 0) DESC, COALESCE(us.Upvotes, 0) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        UserVoteSummary us ON u.Id = us.UserId
    LEFT JOIN 
        PostSummary ps ON u.Id = ps.OwnerUserId
)
SELECT 
    uar.DisplayName,
    uar.Upvotes,
    uar.Downvotes,
    uar.TotalVotes,
    uar.TotalPosts,
    uar.TotalScore,
    uar.AvgViews,
    uar.TotalAnswers,
    uar.ActivityRank
FROM 
    UserActivityRanked uar
WHERE 
    uar.ActivityRank <= 10
ORDER BY 
    uar.ActivityRank;