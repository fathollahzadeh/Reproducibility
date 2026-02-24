
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(AVG(b.Class), 0) AS AverageBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        PostLinks pl ON pl.PostId = p.Id
    LEFT JOIN 
        Tags t ON t.Id = pl.RelatedPostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.*,
        RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY CAST(rp.CreationDate AS DATE) ORDER BY rp.ViewCount DESC) AS RankPerDay
    FROM 
        RankedPosts rp
    WHERE 
        rp.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months' 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.Tags,
    fp.CommentCount,
    fp.AnswerCount,
    fp.AverageBadgeClass,
    fp.RankScore,
    fp.RankPerDay
FROM 
    FilteredPosts fp
WHERE 
    (fp.RankScore <= 10 OR fp.RankPerDay <= 5) 
ORDER BY 
    fp.RankScore, fp.RankPerDay;
