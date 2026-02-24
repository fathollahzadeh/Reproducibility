
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostTypeName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TagPostCounts AS (
    SELECT 
        unnest(string_to_array(Tags, '> <')) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL 
    GROUP BY 
        unnest(string_to_array(Tags, '> <'))
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByCount
    FROM 
        TagPostCounts
    WHERE 
        PostCount > 10
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.OwnerDisplayName,
        rp.PostTypeName,
        pt.Name AS CloseReason,
        CASE 
            WHEN rp.LastActivityDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months' THEN 'Inactivity Detected'
            ELSE 'Active'
        END AS ActivityStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes pt ON ph.Comment = CAST(pt.Id AS VARCHAR)
    WHERE 
        rp.RankByViews <= 5
)
SELECT 
    pp.Title,
    pp.ViewCount,
    pp.AnswerCount,
    pp.CommentCount,
    pp.CreationDate,
    pp.LastActivityDate,
    pp.OwnerDisplayName,
    pp.PostTypeName,
    pt.TagName,
    pt.PostCount,
    pp.CloseReason,
    pp.ActivityStatus
FROM 
    PopularPosts pp
JOIN 
    PopularTags pt ON pp.Title ILIKE '%' || pt.TagName || '%'
ORDER BY 
    pp.ViewCount DESC, 
    pp.CreationDate DESC;
