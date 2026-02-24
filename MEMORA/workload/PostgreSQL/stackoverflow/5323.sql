WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyFromVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostsWithTag
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%%')
    GROUP BY 
        t.TagName
),
TopUsers AS (
    SELECT 
        us.UserId, 
        us.DisplayName, 
        us.Reputation,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalScore,
        us.TotalCommentScore,
        us.TotalBountyFromVotes,
        ROW_NUMBER() OVER (ORDER BY us.TotalScore DESC) AS Rank
    FROM 
        UserStatistics us
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalScore,
    tu.TotalCommentScore,
    tu.TotalBountyFromVotes,
    tg.TagName,
    tg.PostsWithTag
FROM 
    TopUsers tu
LEFT JOIN 
    TagUsage tg ON tu.TotalPosts > 0
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank, tg.PostsWithTag DESC

