
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COALESCE(SUM(v.vote_count), 0) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT 
            v.UserId,
            COUNT(v.Id) AS vote_count
        FROM 
            Votes v
        GROUP BY 
            v.UserId
    ) v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
), TopUserPosts AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        UserStats up
    JOIN 
        RankedPosts rp ON up.UserId = rp.OwnerUserId
    WHERE 
        rp.rn = 1
)
SELECT 
    tup.UserId,
    tup.DisplayName,
    tup.Title,
    tup.CreationDate,
    tup.Score,
    tup.ViewCount,
    us.QuestionCount,
    us.TotalBadges,
    us.TotalVotes
FROM 
    TopUserPosts tup
JOIN 
    UserStats us ON tup.UserId = us.UserId
ORDER BY 
    us.QuestionCount DESC, 
    us.TotalVotes DESC;
