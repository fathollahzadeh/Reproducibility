
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.UserDisplayName || ' edited at ' || ph.CreationDate || ': ' || ph.Comment, ', ') AS EditHistory
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS UseCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        t.TagName
    ORDER BY 
        UseCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    rp.CommentCount,
    rp.RankByViews,
    rph.EditHistory,
    tt.TagName AS TopTag,
    tt.UseCount AS TagUseCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId
CROSS JOIN 
    TopTags tt
ORDER BY 
    rp.RankByViews ASC, 
    rp.CreationDate DESC
LIMIT 100;
