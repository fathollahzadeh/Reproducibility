
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.Score > 10
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        COALESCE(a.Id, -1) AS AcceptedAnswerId,
        COALESCE(c.UserDisplayName, 'No Comments') AS LastCommenter,
        COUNT(c.Id) AS TotalComments,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts a ON rp.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.AnswerCount, rp.CommentCount, a.Id, c.UserDisplayName, rp.Rank
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.LastCommenter,
    pd.TotalComments,
    CASE 
        WHEN pd.Rank <= 3 THEN 'Top Performer'
        ELSE 'Regular Performer'
    END AS PerformanceCategory
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 50;
