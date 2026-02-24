WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        CommentCount, 
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.Score, 
    tp.ViewCount, 
    tp.CommentCount, 
    tp.VoteCount, 
    u.DisplayName AS AuthorDisplayName, 
    u.Reputation, 
    COALESCE(b.GoldCount, 0) AS GoldBadges,
    COALESCE(b.SilverCount, 0) AS SilverBadges,
    COALESCE(b.BronzeCount, 0) AS BronzeBadges
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId = u.Id
LEFT JOIN (
    SELECT 
        UserId, 
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Badges 
    GROUP BY 
        UserId
) b ON u.Id = b.UserId
ORDER BY 
    tp.Score DESC;