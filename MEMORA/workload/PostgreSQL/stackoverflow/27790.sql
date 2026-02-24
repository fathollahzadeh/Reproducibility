WITH ComputedTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount,
        COUNT(DISTINCT pt.OwnerUserId) AS UserCount,
        AVG(pt.Score) AS AverageScore
    FROM 
        ComputedTags ct
    JOIN 
        Posts pt ON ct.PostId = pt.Id
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        UserCount,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, AverageScore DESC) AS Rank
    FROM 
        TagStatistics
)
SELECT 
    t.Tag,
    t.PostCount,
    t.UserCount,
    t.AverageScore,
    COALESCE(b.BadgeName, 'No Badge') AS BadgeName,
    COUNT(DISTINCT b.UserId) AS BadgeWinners
FROM 
    TopTags t
LEFT JOIN 
    (
        SELECT 
            b.Name AS BadgeName,
            b.UserId
        FROM 
            Badges b
        WHERE 
            b.Class = 1 OR b.Class = 2  
    ) b ON t.UserCount >= 10 
WHERE 
    t.Rank <= 10 
GROUP BY 
    t.Tag, t.PostCount, t.UserCount, t.AverageScore, b.BadgeName
ORDER BY 
    t.PostCount DESC, t.AverageScore DESC;