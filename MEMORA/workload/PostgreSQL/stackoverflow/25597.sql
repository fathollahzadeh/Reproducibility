
WITH TagFrequency AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS Frequency
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))
),
PopularTags AS (
    SELECT 
        TagName,
        Frequency,
        RANK() OVER (ORDER BY Frequency DESC) AS TagRank
    FROM 
        TagFrequency
    WHERE 
        Frequency > 1
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopTagPostCounts AS (
    SELECT
        tf.TagName,
        COUNT(p.Id) AS PostCount
    FROM
        TagFrequency tf
    JOIN
        Posts p ON p.Tags LIKE '%' || tf.TagName || '%'
    GROUP BY
        tf.TagName
)
SELECT 
    t.TagName,
    tp.PostCount AS TotalPosts,
    pu.DisplayName AS TopUser,
    pu.TotalViews,
    pu.TotalScore
FROM 
    PopularTags t
LEFT JOIN 
    TopTagPostCounts tp ON tp.TagName = t.TagName
LEFT JOIN 
    TopUsers pu ON pu.PostCount = (
        SELECT MAX(PostCount)
        FROM TopUsers
        WHERE UserId IN (SELECT OwnerUserId FROM Posts WHERE Tags LIKE '%' || t.TagName || '%')
    )
WHERE 
    t.TagRank <= 10 
ORDER BY 
    t.Frequency DESC;
