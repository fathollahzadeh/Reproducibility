WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
ActiveBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY 
        b.UserId
),
HighScorePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.OwnerDisplayName,
        ab.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        ActiveBadges ab ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = ab.UserId)
    WHERE 
        rp.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
)
SELECT 
    hsp.Title,
    hsp.CreationDate,
    hsp.Score,
    hsp.ViewCount,
    hsp.AnswerCount,
    hsp.OwnerDisplayName,
    hsp.BadgeCount
FROM 
    HighScorePosts hsp
WHERE 
    hsp.BadgeCount > 0 
ORDER BY 
    hsp.Score DESC, hsp.ViewCount DESC;