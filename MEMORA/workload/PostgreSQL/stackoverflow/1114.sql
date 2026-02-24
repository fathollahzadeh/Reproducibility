
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
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
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerName,
        CreationDate,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        rn <= 10
),
PostStatistics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerName,
        tp.CreationDate,
        tp.CommentCount,
        (tp.UpVotes - tp.DownVotes) AS NetVotes,
        COALESCE((SELECT AVG(u.Reputation) FROM Users u WHERE u.LastAccessDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'), 0) AS AvgUserReputation
    FROM 
        TopPosts tp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerName,
    ps.CreationDate,
    ps.CommentCount,
    ps.NetVotes,
    ps.AvgUserReputation,
    CASE 
        WHEN ps.NetVotes > 50 THEN 'Hot'
        WHEN ps.NetVotes BETWEEN 20 AND 50 THEN 'Trending'
        ELSE 'Normal'
    END AS PostStatus
FROM 
    PostStatistics ps
ORDER BY 
    ps.NetVotes DESC
LIMIT 10;
