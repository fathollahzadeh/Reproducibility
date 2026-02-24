
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostsWithBadges AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.CreationDate,
        tp.OwnerDisplayName,
        b.Name AS BadgeName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Badges b ON tp.PostId = b.UserId
    GROUP BY 
        tp.PostId, tp.Title, tp.Score, tp.CreationDate, tp.OwnerDisplayName, b.Name
),
FinalResults AS (
    SELECT 
        pwp.PostId,
        pwp.Title,
        pwp.Score,
        pwp.CreationDate,
        pwp.OwnerDisplayName,
        COALESCE(pwp.BadgeName, 'No Badge') AS BadgeName,
        pwp.BadgeCount
    FROM 
        PostsWithBadges pwp
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.CreationDate,
    fr.OwnerDisplayName,
    fr.BadgeName,
    fr.BadgeCount,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
FROM 
    FinalResults fr
LEFT JOIN 
    Comments c ON fr.PostId = c.PostId
LEFT JOIN 
    Votes v ON fr.PostId = v.PostId
GROUP BY 
    fr.PostId, fr.Title, fr.Score, fr.CreationDate, fr.OwnerDisplayName, fr.BadgeName, fr.BadgeCount
ORDER BY 
    fr.Score DESC, fr.CreationDate DESC;
