
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByType
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, u.DisplayName, p.CreationDate, p.Score, p.PostTypeId
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerUserId, 
        OwnerDisplayName, 
        CreationDate, 
        Score, 
        CommentCount, 
        UpVotes, 
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        RankByType <= 5
)
SELECT 
    t.OwnerDisplayName,
    t.Title,
    t.Score,
    t.CommentCount,
    t.UpVotes,
    t.DownVotes,
    ph.CreationDate AS HistoryCreationDate,
    pht.Name AS PostHistoryType,
    ph.Comment AS EditComment
FROM 
    TopRankedPosts t
LEFT JOIN 
    PostHistory ph ON t.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
ORDER BY 
    t.Score DESC, t.PostId ASC;
