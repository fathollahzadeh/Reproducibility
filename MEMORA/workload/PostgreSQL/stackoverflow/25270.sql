WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY t.Id ORDER BY p.CreationDate DESC) AS PostRank,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.TagName,
        COALESCE(PH.RevisionsCount, 0) AS RevisionsCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS RevisionsCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId NOT IN (10, 12)  
        GROUP BY 
            PostId
    ) PH ON rp.PostId = PH.PostId
    WHERE 
        rp.PostRank <= 5  
)
SELECT 
    fp.*,
    PH.Comment AS PostEditComment
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistory PH ON fp.PostId = PH.PostId
WHERE 
    PH.PostHistoryTypeId IN (4, 5, 6)  
ORDER BY 
    fp.TagName, fp.Score DESC, fp.RevisionsCount DESC;