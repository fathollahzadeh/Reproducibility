
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),

TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.ViewCount) AS AvgViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),

RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        STRING_AGG(DISTINCT ph.UserDisplayName, ', ') AS Editors
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId, ph.CreationDate
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    ts.TotalPosts,
    ts.TotalScore,
    ts.AvgScore,
    ts.TotalViews,
    ts.AvgViews,
    re.EditDate,
    re.Editors,
    rp.RankByScore,
    rp.RankByViews
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStats ts ON ts.TagName IN (SELECT unnest(string_to_array(rp.Tags, '>')))
LEFT JOIN 
    RecentEdits re ON re.PostId = rp.PostId
WHERE 
    rp.RankByScore <= 5 OR rp.RankByViews <= 5 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
