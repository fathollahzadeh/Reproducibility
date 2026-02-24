
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.ViewCount DESC, p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND p.Body IS NOT NULL 
),

MostDiscussed AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS TotalComments
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
),

TagStats AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS TagName,
        COUNT(*) AS TagPostCount,
        SUM(CASE WHEN AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        unnest(string_to_array(Tags, '>'))
),

AggregatedTags AS (
    SELECT 
        t.TagName,
        ts.TagPostCount,
        ts.AcceptedAnswers,
        COALESCE(SUM(mp.Score), 0) AS TotalScore,
        COALESCE(SUM(mp.ViewCount), 0) AS TotalViews
    FROM 
        TagStats ts
    JOIN 
        Tags t ON t.TagName = ts.TagName
    LEFT JOIN 
        MostDiscussed mp ON mp.Tags LIKE CONCAT('%', t.TagName, '%') 
    GROUP BY 
        t.TagName, ts.TagPostCount, ts.AcceptedAnswers
)

SELECT 
    at.TagName,
    at.TagPostCount,
    at.AcceptedAnswers,
    at.TotalScore,
    at.TotalViews,
    (CAST(at.TotalScore AS DECIMAL) / NULLIF(at.TagPostCount, 0)) AS AvgScorePerPost,
    (CAST(at.TotalViews AS DECIMAL) / NULLIF(at.TagPostCount, 0)) AS AvgViewsPerPost
FROM 
    AggregatedTags at
ORDER BY 
    AvgScorePerPost DESC
LIMIT 10;
