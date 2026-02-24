
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.PostTypeId, p.CreationDate
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 10
)
SELECT 
    f.Title,
    f.Score,
    f.ViewCount,
    f.CommentCount,
    f.VoteCount,
    f.UpVotes,
    f.DownVotes,
    CONCAT('{',
        '"Score": ', f.Score, ', ',
        '"ViewCount": ', f.ViewCount, ', ',
        '"CommentCount": ', f.CommentCount, ', ',
        '"VoteCount": ', f.VoteCount, ', ',
        '"UpVotes": ', f.UpVotes, ', ',
        '"DownVotes": ', f.DownVotes,
    '}') AS Stats
FROM 
    FilteredPosts f
ORDER BY 
    f.Score DESC;
