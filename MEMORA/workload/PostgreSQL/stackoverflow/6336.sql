
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),

TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        CommentCount, 
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)

SELECT 
    u.DisplayName AS Author, 
    tp.Title AS PostTitle, 
    tp.Score AS PostScore, 
    tp.CommentCount AS TotalComments,
    tp.VoteCount AS TotalVotes,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    tp.CreationDate
FROM 
    TopRankedPosts tp
LEFT JOIN 
    Users u ON u.Id = (SELECT AcceptedAnswerId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date > tp.CreationDate
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;
