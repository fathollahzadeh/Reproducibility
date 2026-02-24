WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(AVG(p.Score), 0) AS AverageScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 100 
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalViews,
        QuestionCount,
        AnswerCount,
        AverageScore,
        RANK() OVER (ORDER BY PostCount DESC, TotalViews DESC) AS Rank
    FROM UserPostStats
    WHERE PostCount > 0
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalViews,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.AverageScore,
    CASE 
        WHEN tu.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributorType,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.UserId = tu.UserId 
     AND v.VoteTypeId IN (2, 3)) AS UpvotesDownvotesCount,
    (SELECT STRING_AGG(DISTINCT p.Tags, ', ') 
     FROM Posts p 
     WHERE p.OwnerUserId = tu.UserId 
     AND p.Tags IS NOT NULL) AS DistinctTags
FROM TopUsers tu
LEFT JOIN Badges b ON tu.UserId = b.UserId
WHERE b.Class = 1 
ORDER BY tu.Rank;