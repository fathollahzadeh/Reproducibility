
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostsWithVotes AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.Score,
    pwv.UpVotes,
    pwv.DownVotes,
    uwb.BadgeCount,
    CASE 
        WHEN uwb.MaxBadgeClass = 1 THEN 'Gold'
        WHEN uwb.MaxBadgeClass = 2 THEN 'Silver'
        WHEN uwb.MaxBadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS MaxBadge
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserWithBadges uwb ON up.Id = uwb.UserId
JOIN 
    PostsWithVotes pwv ON rp.PostId = pwv.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, uwb.BadgeCount DESC
LIMIT 10;
