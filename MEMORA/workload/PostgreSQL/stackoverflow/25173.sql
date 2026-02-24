WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.ViewCount > 100 
),
PopularTags AS (
    SELECT 
        CASE 
            WHEN t.TagName IS NOT NULL THEN t.TagName
            ELSE 'No Tag' 
        END AS Tag,
        COUNT(p.Id) AS PostsCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_name ON true
    LEFT JOIN 
        Tags t ON tag_name = t.TagName
    GROUP BY 
        Tag
    ORDER BY 
        PostsCount DESC
    LIMIT 10
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        PHT.Name AS HistoryType,
        COUNT(*) AS ChangesCount,
        MIN(ph.CreationDate) AS FirstChangeDate,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    GROUP BY 
        ph.PostId, PHT.Name
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    pt.Tag,
    phs.HistoryType,
    phs.ChangesCount,
    phs.FirstChangeDate,
    phs.LastChangeDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
JOIN 
    PopularTags pt ON pt.TotalViews > 1000 
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.ViewCount DESC;