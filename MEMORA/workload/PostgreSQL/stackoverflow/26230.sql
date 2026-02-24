
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        CONCAT(SUBSTRING(p.Body, 1, 100), '...') AS ShortenedBody,
        p.CreationDate,
        COUNT(c.Id) AS CommentsCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), 
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.ShortenedBody,
    rp.CreationDate,
    rp.CommentsCount,
    rp.UpVotes,
    rp.DownVotes,
    uwb.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UsersWithBadges uwb ON u.Id = uwb.UserId
WHERE 
    rp.PostRank = 1  
ORDER BY 
    uwb.BadgeCount DESC,
    rp.CreationDate DESC
LIMIT 50;
