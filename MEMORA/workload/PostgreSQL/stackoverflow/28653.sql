WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    LEFT JOIN (
        SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount 
        FROM Posts 
        WHERE PostTypeId = 2 
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        STRING_AGG(c.Text, ' | ') AS CommentText
    FROM RankedPosts rp
    LEFT JOIN Comments c ON rp.PostId = c.PostId
    WHERE rp.Rank <= 3 
    GROUP BY rp.PostId, rp.Title, rp.Body, rp.Tags, rp.CreationDate, rp.ViewCount, rp.AnswerCount, rp.CommentCount
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.CreationDate,
    fp.ViewCount,
    fp.AnswerCount,
    fp.CommentCount,
    fp.CommentText,
    ARRAY_LENGTH(STRING_TO_ARRAY(fp.Tags, ','), 1) AS TagCount,
    CASE 
        WHEN fp.ViewCount > 1000 THEN 'High View Count' 
        WHEN fp.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate View Count' 
        ELSE 'Low View Count' 
    END AS ViewCountCategory
FROM FilteredPosts fp
ORDER BY fp.CreationDate DESC;