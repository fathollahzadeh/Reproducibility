
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionsPosted,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswersPosted,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        QuestionsPosted,
        AnswersPosted,
        TotalScore,
        TotalBounty,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM UserStatistics
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.Reputation,
    t.TotalPosts,
    t.QuestionsPosted,
    t.AnswersPosted,
    t.TotalScore,
    t.TotalBounty,
    CASE 
        WHEN t.Rank <= 10 THEN 'Top Contributor'
        WHEN t.Rank <= 50 THEN 'High Contributor'
        ELSE 'Contributor'
    END AS ContributorLevel
FROM TopUsers t
WHERE t.TotalPosts >= 5
ORDER BY t.TotalScore DESC, ContributorLevel;
