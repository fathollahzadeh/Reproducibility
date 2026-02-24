
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        RANK() OVER (ORDER BY p.Score DESC) AS PostRank
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
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 100
)
SELECT 
    t.PostId,
    t.Title,
    t.ViewCount,
    t.OwnerDisplayName,
    t.CommentCount,
    t.UpVoteCount,
    t.DownVoteCount,
    t.CreationDate,
    pt.Name AS PostTypeName,
    COUNT(DISTINCT bl.Id) AS RelatedLinksCount
FROM 
    TopPosts t
LEFT JOIN 
    PostTypes pt ON t.PostId IN (SELECT p.Id FROM Posts p WHERE p.PostTypeId = pt.Id)
LEFT JOIN 
    PostLinks bl ON t.PostId = bl.PostId
GROUP BY 
    t.PostId, t.Title, t.ViewCount, t.OwnerDisplayName, t.CommentCount,
    t.UpVoteCount, t.DownVoteCount, t.CreationDate, pt.Name
ORDER BY 
    t.ViewCount DESC, t.CreationDate DESC;
