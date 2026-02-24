
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        CASE 
            WHEN COUNT(b.Id) > 10 THEN 'Gold'
            WHEN COUNT(b.Id) > 5 THEN 'Silver'
            ELSE 'Bronze'
        END AS BadgeLevel
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    rb.BadgeLevel,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(pvc.UpVotes) AS TotalUpVotes,
    SUM(pvc.DownVotes) AS TotalDownVotes,
    AVG(rp.Score) AS AvgScore,
    AVG(rp.ViewCount) AS AvgViewCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Users u
JOIN 
    UserBadges rb ON u.Id = rb.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId 
LEFT JOIN 
    PostVoteCounts pvc ON rp.PostId = pvc.PostId
LEFT JOIN 
    (SELECT 
        p.OwnerUserId, 
        TRIM(UNNEST(STRING_TO_ARRAY(p.Tags, ','))) AS TagName
     FROM 
        Posts p) AS t ON t.OwnerUserId = u.Id
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id,
    u.DisplayName,
    rb.BadgeLevel
HAVING 
    COUNT(DISTINCT rp.PostId) > 5 
ORDER BY 
    AvgScore DESC, 
    TotalPosts DESC 
LIMIT 10
OFFSET 0;
