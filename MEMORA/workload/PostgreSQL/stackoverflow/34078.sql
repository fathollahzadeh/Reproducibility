WITH RECURSIVE PostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        COALESCE(p.AcceptedAnswerId, -1),
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostCTE cte ON p.ParentId = cte.Id
),
PostMetrics AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.Score
),
ClosingHistory AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
),
RankedPosts AS (
    SELECT 
        pm.*,
        RANK() OVER (ORDER BY pm.Score DESC, pm.ViewCount DESC) AS Rank
    FROM 
        PostMetrics pm
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.Tags,
    CASE 
        WHEN ch.LastCloseDate IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    rp.Rank,
    u.DisplayName AS MostActiveUser 
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON u.Id = (
        SELECT 
            v.UserId
        FROM 
            Votes v
        WHERE 
            v.PostId = rp.Id
        ORDER BY 
            v.CreationDate DESC 
        LIMIT 1
    )
LEFT JOIN 
    ClosingHistory ch ON ch.PostId = rp.Id
WHERE 
    rp.Rank <= 100  
ORDER BY 
    rp.Rank;