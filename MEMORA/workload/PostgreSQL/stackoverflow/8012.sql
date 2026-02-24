
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Owner,
        r.CreationDate,
        r.Score
    FROM 
        RankedPosts r
    WHERE 
        r.Rank <= 5
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Owner,
        tp.CreationDate,
        tp.Score,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.Owner, tp.CreationDate, tp.Score
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Owner,
    pd.CreationDate,
    pd.Score,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    CASE 
        WHEN pd.Score >= 50 THEN 'Highly Active'
        WHEN pd.Score >= 20 THEN 'Moderately Active'
        ELSE 'Less Active' 
    END AS ActivityLevel
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC;
