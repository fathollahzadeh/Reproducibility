
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(COALESCE(v.Score, 0)) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (
            SELECT 
                PostId,
                SUM(CASE WHEN VoteTypeId = 2 THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS Score
            FROM 
                Votes 
            GROUP BY 
                PostId
        ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), PopularTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        (
            SELECT 
                UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS TagName
            FROM 
                Posts
            WHERE 
                PostTypeId = 1
        ) AS TagsList
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
)

SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.AverageScore,
    pt.TagName,
    pt.TagCount
FROM 
    UserPostStats ups
CROSS JOIN 
    PopularTags pt
WHERE 
    ups.TotalPosts > 10
ORDER BY 
    ups.AverageScore DESC, pt.TagCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
