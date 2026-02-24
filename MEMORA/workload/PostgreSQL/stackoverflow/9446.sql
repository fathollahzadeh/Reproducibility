
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        OwnerRank <= 10
),
PostDetails AS (
    SELECT 
        tp.Id,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        (SELECT COUNT(DISTINCT pl.RelatedPostId) 
         FROM PostLinks pl 
         WHERE pl.PostId = tp.Id) AS RelatedPostsCount,
        (SELECT COUNT(b.Id) 
         FROM Badges b 
         WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.Id)) AS UserBadgesCount,
        (SELECT COUNT(DISTINCT v.VoteTypeId) 
         FROM Votes v 
         WHERE v.PostId = tp.Id) AS TotalVotes
    FROM 
        TopPosts tp
)
SELECT 
    pd.Id,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.RelatedPostsCount,
    pd.UserBadgesCount,
    pd.TotalVotes
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
