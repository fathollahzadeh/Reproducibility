
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagUsage
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagUsage DESC
    LIMIT 10
),
TopUsers AS (
    SELECT 
        ws.UserId,
        ws.DisplayName,
        ws.TotalPosts,
        ws.Questions,
        ws.Answers,
        ws.TotalScore,
        ws.AvgViews,
        pt.TagName,
        ROW_NUMBER() OVER (PARTITION BY pt.TagName ORDER BY ws.TotalScore DESC) AS Rank
    FROM 
        UserPostStats ws
    JOIN 
        PopularTags pt ON ws.UserId IN (
            SELECT 
                u.Id
            FROM 
                Users u
            JOIN 
                Posts p ON u.Id = p.OwnerUserId
            WHERE 
                p.Tags LIKE CONCAT('%', pt.TagName, '%')
        )
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.TotalScore,
    tu.AvgViews,
    tu.TagName
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 5
ORDER BY 
    tu.TagName, tu.TotalScore DESC;
