
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScores,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(p.Score) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts,
        Questions,
        Answers,
        TotalScore,
        TotalCommentScores,
        Rank
    FROM UserStats
    WHERE TotalPosts > 0
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS Tag,
        COUNT(*) AS TagCount
    FROM Posts
    GROUP BY Tag
    HAVING COUNT(*) > 10
),
UserTagStats AS (
    SELECT 
        u.Id AS UserId,
        t.Tag,
        COUNT(*) AS TagUsage
    FROM 
        Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    JOIN PopularTags t ON t.Tag = ANY (string_to_array(p.Tags, ','))
    GROUP BY u.Id, t.Tag
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.TotalScore,
    tu.TotalCommentScores,
    ut.Tag,
    COALESCE(ut.TagUsage, 0) AS TagUsageCount
FROM 
    TopUsers tu
LEFT JOIN UserTagStats ut ON tu.UserId = ut.UserId
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.TotalScore DESC,
    tu.DisplayName ASC;
