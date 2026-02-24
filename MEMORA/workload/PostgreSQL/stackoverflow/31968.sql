
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.Comment,
        ph.CreationDate,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
),
FinalPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.RankByScore,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        ph.UserDisplayName AS LastEditor,
        ph.Comment AS LastEditComment
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryCTE ph ON rp.PostId = ph.PostId AND ph.EditRank = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.RankByScore,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    COALESCE(fp.LastEditor, 'No edits yet') AS LastEditor,
    COALESCE(fp.LastEditComment, 'N/A') AS LastEditComment
FROM 
    FinalPosts fp
WHERE 
    (fp.Score > 10 OR fp.ViewCount > 100) 
    AND fp.RankByScore <= 5
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC;
