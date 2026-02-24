WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.Score DESC, p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 /* Questions */
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' /* Last year */
),

TopPostOwners AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS PostCount,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(CommentCount) AS TotalComments
    FROM 
        RankedPosts
    WHERE 
        OwnerPostRank <= 5 /* Top 5 posts per user */
    GROUP BY 
        OwnerDisplayName
),

TopTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '>'))::text) AS Tag,
        COUNT(*) AS UsageCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 /* Questions */
        AND Tags IS NOT NULL
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10
)

SELECT 
    o.OwnerDisplayName,
    o.PostCount,
    o.TotalScore,
    o.TotalViews,
    o.TotalAnswers,
    o.TotalComments,
    t.Tag,
    t.UsageCount
FROM 
    TopPostOwners o
JOIN 
    TopTags t ON o.PostCount > 5 /* Arbitrary filter for engagement */
ORDER BY 
    o.TotalScore DESC, o.OwnerDisplayName, t.UsageCount DESC;