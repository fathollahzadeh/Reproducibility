WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON POSITION(CONCAT('<', t.TagName, '>') IN p.Tags) > 0
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName
), HistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE WHEN pht.Name = 'Edit Body' THEN ph.Comment END, '; ') AS EditBodyComments,
        STRING_AGG(CASE WHEN pht.Name IN ('Post Closed', 'Post Reopened') THEN ph.Comment END, '; ') AS ClosureComments,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.AnswerCount,
    pm.Tags,
    pm.OwnerDisplayName,
    pm.CommentCount,
    pm.UpVoteCount,
    pm.DownVoteCount,
    hd.EditBodyComments,
    hd.ClosureComments,
    hd.LastHistoryDate
FROM 
    PostMetrics pm
LEFT JOIN 
    HistoryDetails hd ON pm.PostId = hd.PostId
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC
LIMIT 100;