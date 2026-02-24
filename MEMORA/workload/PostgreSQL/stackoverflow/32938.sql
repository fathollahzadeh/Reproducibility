
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.Reputation,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    INNER JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        Id, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        Reputation
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 5
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, ', ') AS EditComments,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    pe.CommentCount,
    pe.UpVoteCount,
    pe.DownVoteCount,
    phd.EditComments,
    phd.LastEditDate
FROM 
    TopPosts tp
LEFT JOIN 
    PostEngagement pe ON tp.Id = pe.PostId
LEFT JOIN 
    PostHistoryData phd ON tp.Id = phd.PostId
WHERE 
    pe.CommentCount > 0 OR pe.UpVoteCount > 0
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
