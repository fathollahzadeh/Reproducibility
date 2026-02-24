WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.ViewCount, p.CreationDate, p.Score
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        CreationDate, 
        Score, 
        OwnerName, 
        CommentCount,
        RankByScore
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5
)
SELECT 
    trp.PostId, 
    trp.Title, 
    trp.ViewCount, 
    trp.CreationDate, 
    trp.Score, 
    trp.OwnerName, 
    trp.CommentCount,
    pt.Name AS PostTypeName,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedLinksCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    TopRankedPosts trp
JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = trp.PostId)
LEFT JOIN 
    PostLinks pl ON trp.PostId = pl.PostId
LEFT JOIN 
    Votes v ON trp.PostId = v.PostId
GROUP BY 
    trp.PostId, trp.Title, trp.ViewCount, trp.CreationDate, trp.Score, trp.OwnerName, trp.CommentCount, pt.Name
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;