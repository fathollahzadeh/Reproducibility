
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.Tags,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),

TagStatistics AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(Score) AS AverageScore
    FROM 
        RecentPosts
    GROUP BY 
        unnest(string_to_array(substring(Tags, 2, LENGTH(Tags) - 2), '><'))
),

TopTags AS (
    SELECT 
        Tag,
        PostCount,
        PositiveScorePosts,
        AverageScore,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)

SELECT 
    t.Tag,
    t.PostCount,
    t.PositiveScorePosts,
    t.AverageScore,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.OwnerDisplayName
FROM 
    TopTags t
JOIN 
    RecentPosts r ON r.Tags LIKE '%' || t.Tag || '%'
WHERE 
    t.TagRank <= 10
ORDER BY 
    t.TagRank, r.Score DESC;
