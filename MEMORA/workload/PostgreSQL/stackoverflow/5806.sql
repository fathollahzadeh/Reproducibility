
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        OwnerDisplayName, 
        CommentCount, 
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
)
SELECT 
    t.OwnerDisplayName,
    COUNT(b.Id) AS BadgeCount,
    AVG(u.Reputation) AS AvgReputation,
    SUM(t.ViewCount) AS TotalViews,
    SUM(t.CommentCount) AS TotalComments,
    SUM(t.VoteCount) AS TotalVotes
FROM 
    TopPosts t
JOIN 
    Users u ON u.DisplayName = t.OwnerDisplayName
LEFT JOIN 
    Badges b ON b.UserId = u.Id
GROUP BY 
    t.OwnerDisplayName
ORDER BY 
    TotalVotes DESC, TotalViews DESC
LIMIT 
    10;
