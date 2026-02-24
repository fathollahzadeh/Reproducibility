WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    WHERE 
        rp.Rank <= 5  
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.Score
)
SELECT 
    p.Title,
    p.OwnerDisplayName,
    p.Score,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    (p.UpVotes - p.DownVotes) AS NetVotes,
    CASE 
        WHEN p.Score > 10 THEN 'High'
        WHEN p.Score BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low' 
    END AS ScoreCategory
FROM 
    TopPosts p
ORDER BY 
    p.Score DESC, p.CommentCount DESC;