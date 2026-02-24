WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
OldPostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score AS OldScore,
        COALESCE(ph.UserDisplayName, 'Unknown') AS LastEditedBy,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5) 
    WHERE 
        p.CreationDate <= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score AS CurrentScore,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ops.OldScore,
    ops.LastEditedBy
FROM 
    PostStatistics ps
LEFT JOIN 
    OldPostStatistics ops ON ps.PostId = ops.PostId AND ops.EditRank = 1
WHERE 
    ps.Score > COALESCE(ops.OldScore, 0)
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;