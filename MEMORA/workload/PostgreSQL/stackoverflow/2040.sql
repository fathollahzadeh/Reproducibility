WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9
    GROUP BY u.Id, u.DisplayName
),
RankedUserPostStats AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalBounty,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM UserPostStats
),
TopContributors AS (
    SELECT 
        r.UserId,
        r.DisplayName,
        r.TotalPosts,
        r.TotalQuestions,
        r.TotalAnswers,
        r.TotalScore,
        r.TotalBounty,
        CASE 
            WHEN r.ScoreRank <= 10 AND r.PostRank <= 10 THEN 'Top 10 in Score and Posts'
            WHEN r.ScoreRank <= 10 THEN 'Top 10 in Score'
            WHEN r.PostRank <= 10 THEN 'Top 10 in Posts'
            ELSE 'Other'
        END AS ContributorCategory
    FROM RankedUserPostStats r
)
SELECT 
    t.DisplayName,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    t.TotalScore,
    t.TotalBounty,
    t.ContributorCategory,
    COALESCE(t2.Reputation, 0) AS Reputation,
    COALESCE(t2.Views, 0) AS Views
FROM TopContributors t
LEFT JOIN Users t2 ON t.UserId = t2.Id
WHERE (t.ContributorCategory = 'Top 10 in Score' OR t.ContributorCategory = 'Top 10 in Posts')
ORDER BY t.TotalScore DESC, t.TotalPosts DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;

