
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),

RankedTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
)

SELECT 
    rt.TagName,
    rt.PostCount,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    AVG(COALESCE(c.Score, 0)) AS AverageCommentScore,
    MAX(p.ViewCount) AS MaxViewCount,
    STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    RankedTags rt
JOIN 
    Posts p ON p.Tags LIKE CONCAT('%', rt.TagName, '%')
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Users u ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON b.UserId = u.Id
WHERE 
    rt.Rank <= 10 
GROUP BY 
    rt.TagName, rt.PostCount
ORDER BY 
    rt.PostCount DESC;
