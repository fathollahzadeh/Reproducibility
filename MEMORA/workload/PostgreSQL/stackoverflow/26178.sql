
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '>')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.Score
),
UserPostStats AS (
    SELECT 
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        COUNT(p.Id) AS TotalPosts,
        MAX(p.CreationDate) AS LatestPostDate,
        MAX(p.Score) AS HighestScore,
        ARRAY_AGG(DISTINCT t.TagName) AS AssociatedTags
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '>')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        u.DisplayName
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        ps.TotalViews,
        ps.TotalAnswers,
        ps.TotalPosts,
        ps.LatestPostDate,
        ps.HighestScore,
        ps.AssociatedTags,
        ROW_NUMBER() OVER (ORDER BY ps.TotalViews DESC) AS ViewRank,
        ROW_NUMBER() OVER (ORDER BY ps.TotalAnswers DESC) AS AnswerRank
    FROM 
        Users u
    JOIN 
        UserPostStats ps ON u.DisplayName = ps.DisplayName
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalViews,
    tu.TotalAnswers,
    tu.TotalPosts,
    tu.LatestPostDate,
    tu.HighestScore,
    tu.AssociatedTags,
    CASE 
        WHEN tu.ViewRank <= 10 THEN 'Top View Users' 
        WHEN tu.AnswerRank <= 10 THEN 'Top Answer Users' 
        ELSE 'Others' 
    END AS UserCategory
FROM 
    TopUsers tu
WHERE 
    tu.Reputation > 1000
ORDER BY 
    tu.TotalViews DESC, 
    tu.TotalAnswers DESC;
