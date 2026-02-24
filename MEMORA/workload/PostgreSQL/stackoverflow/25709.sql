
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS Tag
    FROM Posts p
    WHERE p.PostTypeId = 1  
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(p.Id) AS PostCount,
        AVG(u.Reputation) AS AverageUserReputation,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueAuthors
    FROM PostTags pt
    JOIN Posts p ON pt.PostId = p.Id
    JOIN Users u ON p.OwnerUserId = u.Id
    GROUP BY Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        AverageUserReputation,
        UniqueAuthors,
        RANK() OVER (ORDER BY PostCount DESC, AverageUserReputation DESC) AS TagRank
    FROM TagStatistics
    WHERE PostCount > 1  
)
SELECT 
    T.Tag,
    T.PostCount,
    ROUND(T.AverageUserReputation, 2) AS AverageUserReputation,
    T.UniqueAuthors,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes
FROM TopTags T
LEFT JOIN Posts p ON T.Tag = ANY(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AND p.PostTypeId = 1
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
WHERE T.TagRank <= 10 
GROUP BY T.Tag, T.PostCount, T.AverageUserReputation, T.UniqueAuthors, T.TagRank
ORDER BY T.TagRank;
