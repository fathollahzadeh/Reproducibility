WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
),
BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    bh.BadgeCount,
    bh.GoldCount,
    bh.SilverCount,
    bh.BronzeCount,
    p.Title AS LatestPostTitle,
    p.CreationDate AS LatestPostDate,
    ph.PostHistoryTypeId,
    ph.CreationDate AS HistoryDate
FROM 
    Users u
LEFT JOIN 
    BadgedUsers bh ON u.Id = bh.UserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.CreationDate = (
        SELECT MAX(CreationDate)
        FROM Posts
        WHERE OwnerUserId = u.Id
    )
LEFT JOIN 
    RecursivePostHistory ph ON p.Id = ph.PostId AND ph.rn = 1
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC, 
    LatestPostDate DESC
FETCH FIRST 10 ROWS ONLY;