
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN bh.Id IS NOT NULL THEN 1 ELSE 0 END) AS EditCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory bh ON p.Id = bh.PostId
    WHERE 
        p.CreationDate >= DATE '2023-01-01'
    GROUP BY 
        p.Id, u.DisplayName, pt.Name
),
PostRankings AS (
    SELECT 
        rp.*,
        DENSE_RANK() OVER (PARTITION BY rp.PostType ORDER BY rp.UpVotes - rp.DownVotes DESC) AS Rank
    FROM 
        RankedPosts rp
)
SELECT 
    pr.PostId,
    pr.Title,
    pr.CreationDate,
    pr.OwnerName,
    pr.PostType,
    pr.CommentCount,
    pr.UpVotes,
    pr.DownVotes,
    pr.EditCount,
    pr.Rank
FROM 
    PostRankings pr
WHERE 
    pr.Rank <= 10
ORDER BY 
    pr.PostType, pr.Rank;
