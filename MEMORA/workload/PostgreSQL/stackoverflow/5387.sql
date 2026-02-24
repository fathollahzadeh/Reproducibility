
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AverageUpVotes,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AverageDownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.AverageUpVotes,
    rp.AverageDownVotes,
    pt.Name AS PostType,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top 5 Latest Posts'
        ELSE 'Other Posts'
    END AS PostRanking
FROM 
    RankedPosts rp
JOIN 
    PostTypes pt ON rp.PostTypeId = pt.Id
WHERE 
    rp.CommentCount > 5
ORDER BY 
    rp.Rank, rp.CommentCount DESC;
