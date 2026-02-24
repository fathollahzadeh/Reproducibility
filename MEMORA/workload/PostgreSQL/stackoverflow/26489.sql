
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        p.ViewCount,
        p.CommentCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Author,
        rp.ViewCount,
        rp.CommentCount,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 3 
),
WordsCount AS (
    SELECT 
        fp.PostId,
        COUNT(DISTINCT TRIM(value)) AS UniqueWordCount
    FROM 
        FilteredPosts fp,
        UNNEST(STRING_TO_ARRAY(fp.Body, ' ')) AS value
    GROUP BY 
        fp.PostId
),
PostBadges AS (
    SELECT 
        fp.PostId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId LIMIT 1)
    GROUP BY 
        fp.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Author,
    fp.CreationDate,
    fp.ViewCount,
    fp.CommentCount,
    fp.Score,
    wc.UniqueWordCount,
    pb.BadgeCount
FROM 
    FilteredPosts fp
JOIN 
    WordsCount wc ON fp.PostId = wc.PostId
JOIN 
    PostBadges pb ON fp.PostId = pb.PostId
ORDER BY 
    fp.CreationDate DESC;
