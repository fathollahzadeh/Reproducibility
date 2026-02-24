
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
HighestRankedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
),
PostWithHistory AS (
    SELECT 
        h.PostId,
        h.UserId,
        h.CreationDate AS HistoryDate,
        DENSE_RANK() OVER (PARTITION BY h.PostId ORDER BY h.CreationDate DESC) AS EditRank
    FROM 
        PostHistory h
    WHERE 
        h.PostHistoryTypeId IN (4, 5, 10) 
)
SELECT 
    hrp.Id AS PostId,
    hrp.Title,
    hrp.CreationDate,
    hrp.Score,
    hrp.UpVotes,
    hrp.DownVotes,
    hrp.CommentCount,
    COUNT(DISTINCT ph.UserId) AS UniqueEditors,
    MAX(ph.HistoryDate) AS LastEditDate,
    STRING_AGG(DISTINCT u.DisplayName, ', ') AS EditorNames
FROM 
    HighestRankedPosts hrp
LEFT JOIN 
    PostWithHistory ph ON hrp.Id = ph.PostId
LEFT JOIN 
    Users u ON ph.UserId = u.Id
GROUP BY 
    hrp.Id, hrp.Title, hrp.CreationDate, hrp.Score, hrp.UpVotes, hrp.DownVotes, hrp.CommentCount
ORDER BY 
    hrp.Score DESC, hrp.CreationDate DESC;
