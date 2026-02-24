
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '365 days'
        AND p.AnswerCount > 0
),
CommentsStats AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END) AS PositiveCommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
BadgesSummary AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS Reasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(cs.CommentCount, 0) AS TotalComments,
    COALESCE(cs.PositiveCommentCount, 0) AS PositiveComments,
    bs.BadgeNames,
    COALESCE(cr.Reasons, 'N/A') AS CloseReasons,
    CASE 
        WHEN rp.Score > 0 THEN 'Popular' 
        WHEN rp.Score < 0 THEN 'Unpopular' 
        ELSE 'Neutral' 
    END AS Popularity
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentsStats cs ON rp.PostId = cs.PostId
LEFT JOIN 
    BadgesSummary bs ON rp.PostId = (SELECT u.Id FROM Users u WHERE u.Id = rp.PostId LIMIT 1)
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC;
