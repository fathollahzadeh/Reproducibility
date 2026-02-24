
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COUNT(DISTINCT CASE WHEN b.Id IS NOT NULL THEN b.Id END) AS TotalBadges,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(p.Score), 0) DESC) AS ScoreRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        COUNT(DISTINCT v.PostId) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
FinalStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalScore,
        ups.TotalBadges,
        uvs.TotalVotes,
        uvs.UpVotes,
        uvs.DownVotes,
        ups.ScoreRank
    FROM 
        UserPostStats ups
    LEFT JOIN 
        UserVoteStats uvs ON ups.UserId = uvs.UserId
)
SELECT 
    *
FROM 
    FinalStats
WHERE 
    TotalScore > 1000
ORDER BY 
    ScoreRank, TotalPosts DESC;
