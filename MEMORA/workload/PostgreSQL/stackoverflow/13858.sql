
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(up.TotalPosts, 0) AS TotalPosts,
    COALESCE(up.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(up.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(up.TotalScore, 0) AS TotalScore,
    COALESCE(up.TotalViews, 0) AS TotalViews,
    COALESCE(uv.TotalVotes, 0) AS TotalVotes,
    COALESCE(uv.UpVotes, 0) AS UpVotes,
    COALESCE(uv.DownVotes, 0) AS DownVotes
FROM 
    Users u
LEFT JOIN 
    UserPostStats up ON u.Id = up.UserId
LEFT JOIN 
    UserVoteStats uv ON u.Id = uv.UserId
ORDER BY 
    TotalPosts DESC, TotalScore DESC;
