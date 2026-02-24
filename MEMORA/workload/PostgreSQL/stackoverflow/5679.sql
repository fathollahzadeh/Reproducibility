
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month')
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Score, p.CreationDate, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.Author,
        rp.Rank,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    t.PostId,
    t.Title,
    t.Score,
    t.CreationDate,
    t.ViewCount,
    t.Author,
    t.CommentCount,
    t.UpVoteCount,
    t.DownVoteCount,
    CASE 
        WHEN t.UpVoteCount = 0 THEN 0 
        ELSE CAST(t.UpVoteCount AS FLOAT) / (t.UpVoteCount + t.DownVoteCount) 
    END AS UpvoteRatio
FROM 
    TopPosts t
ORDER BY 
    t.Score DESC, t.ViewCount DESC;
