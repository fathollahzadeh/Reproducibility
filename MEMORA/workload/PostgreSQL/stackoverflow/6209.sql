
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.ViewCount,
        DENSE_RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.ViewCount, pt.Name
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        OwnerDisplayName, 
        CommentCount, 
        (UpVotes - DownVotes) AS NetVotes,
        PostRank
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
)
SELECT 
    tp.*,
    CASE 
        WHEN tp.NetVotes >= 10 THEN 'Hot'
        WHEN tp.CommentCount >= 5 THEN 'Active'
        ELSE 'Archived' 
    END AS Status
FROM 
    TopPosts tp
ORDER BY 
    tp.NetVotes DESC, 
    tp.CreationDate DESC;
