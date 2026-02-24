
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 
                         WHEN v.VoteTypeId = 3 THEN -1 
                         ELSE 0 END), 0) AS Score
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        FilteredPosts
    GROUP BY 
        unnest(string_to_array(Tags, '><'))
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.OwnerDisplayName,
        fp.CreationDate,
        fp.CommentCount,
        fp.Score,
        phs.EditCount,
        phs.LastEditDate,
        (SELECT ARRAY_AGG(pt.TagName) FROM PopularTags pt) AS PopularTags
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostHistoryStats phs ON fp.PostId = phs.PostId
)
SELECT 
    *
FROM 
    FinalResults
ORDER BY 
    Score DESC, CommentCount DESC;
