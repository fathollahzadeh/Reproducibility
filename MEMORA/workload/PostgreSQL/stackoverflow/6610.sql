
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rb.Name AS BadgeName,
        rb.Class
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges rb ON rp.PostId = rb.UserId
    WHERE 
        rp.RankByScore <= 5 
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.OwnerDisplayName,
    pwb.Score,
    pwb.ViewCount,
    STRING_AGG(DISTINCT CONCAT(pwb.BadgeName, ' (Class: ', pwb.Class, ')'), ', ') AS Badges
FROM 
    PostWithBadges pwb
GROUP BY 
    pwb.PostId, pwb.Title, pwb.OwnerDisplayName, pwb.Score, pwb.ViewCount
ORDER BY 
    pwb.Score DESC, COUNT(pwb.BadgeName) DESC;
