
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.Score
),
TopQuestions AS (
    SELECT 
        PostId, 
        Title, 
        CommentCount
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 5 
        AND CommentCount > 0
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        ph.CreationDate, 
        COALESCE(u.DisplayName, 'System') AS UserDisplayName,
        ph.Comment,
        ph.Text,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 52, 66) 
),
CommentsSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
)
SELECT 
    tq.PostId, 
    tq.Title,
    tq.CommentCount,
    ph.UserDisplayName,
    ph.Comment,
    ph.Text,
    ph.CreationDate AS HistoryDate,
    cs.TotalCommentScore,
    cs.TotalComments
FROM 
    TopQuestions tq
JOIN 
    PostHistoryDetails ph ON tq.PostId = ph.PostId
JOIN 
    CommentsSummary cs ON tq.PostId = cs.PostId
WHERE 
    ph.HistoryRank = 1
    AND (cs.TotalCommentScore IS NULL OR cs.TotalCommentScore >= 10)
ORDER BY 
    tq.CommentCount DESC, 
    ph.CreationDate DESC;
