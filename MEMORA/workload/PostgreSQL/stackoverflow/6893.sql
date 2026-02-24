
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT PostId, Title, OwnerDisplayName, Score, ViewCount, CreationDate, CommentCount, UpVoteCount, DownVoteCount
    FROM RankedPosts
    WHERE Rank <= 10
)
SELECT 
    t.PostId,
    t.Title,
    t.OwnerDisplayName,
    t.Score,
    t.ViewCount,
    t.CreationDate,
    t.CommentCount,
    t.UpVoteCount,
    t.DownVoteCount,
    CASE 
        WHEN t.UpVoteCount > t.DownVoteCount THEN 'Positive'
        WHEN t.UpVoteCount < t.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    TopPosts t
ORDER BY 
    t.Score DESC, t.CreationDate DESC;
