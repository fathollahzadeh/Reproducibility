
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Author,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName, p.OwnerUserId, p.Title, p.Body, p.Tags, p.CreationDate
),
BadgedUsers AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.Author,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    bu.GoldBadges,
    bu.SilverBadges,
    bu.BronzeBadges,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Latest Question'
        ELSE 'Older Question'
    END AS RankingStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    BadgedUsers bu ON rp.OwnerUserId = bu.UserId
WHERE 
    rp.UpVotes > 5  
ORDER BY 
    rp.CreationDate DESC
LIMIT 10;
