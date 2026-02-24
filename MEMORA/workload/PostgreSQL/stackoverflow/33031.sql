WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score > 0
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(p.Tags, '><'))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.Score,
    rp.OwnerName,
    COALESCE(pwc.CommentCount, 0) AS CommentCount,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    ARRAY_AGG(DISTINCT pt.TagName) AS AssociatedTags
FROM 
    RankedPosts rp
LEFT JOIN 
    PostsWithComments pwc ON rp.PostId = pwc.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY(STRING_TO_ARRAY(p.Tags, '><'))
WHERE 
    rp.Rank <= 5
GROUP BY 
    rp.PostId, rp.Title, rp.ViewCount, rp.CreationDate, rp.Score, rp.OwnerName, pwc.CommentCount, cp.CloseCount
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;