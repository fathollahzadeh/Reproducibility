
WITH RecursiveUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS rn
    FROM 
        Users u
    WHERE 
        u.Views IS NOT NULL
),
VoteDetails AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            ELSE 0 
        END) AS UpVotes,
        SUM(CASE 
            WHEN v.VoteTypeId = 3 THEN 1 
            ELSE 0 
        END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > '2023-01-01' 
        AND (p.Title LIKE '%SQL%' OR p.Body LIKE '%SQL%')
    GROUP BY 
        p.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(Ph.CreationDate), '1970-01-01') AS LastEditDate,
        PHT.Name AS LastPostHistoryType
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory Ph ON p.Id = Ph.PostId
    LEFT JOIN 
        PostHistoryTypes PHT ON Ph.PostHistoryTypeId = PHT.Id
    GROUP BY 
        p.Id, PHT.Name
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(vd.TotalVotes, 0) AS TotalVotes,
    COALESCE(vd.UpVotes, 0) AS UpVotes,
    COALESCE(vd.DownVotes, 0) AS DownVotes,
    COALESCE(pa.CommentCount, 0) AS CommentCount,
    pa.LastEditDate,
    pa.LastPostHistoryType,
    ub.Badges,
    ub.BadgeCount
FROM 
    Users u
LEFT JOIN 
    VoteDetails vd ON u.Id = vd.PostId
LEFT JOIN 
    PostActivity pa ON u.Id = (SELECT p.OwnerUserId FROM Posts p WHERE p.OwnerUserId = u.Id LIMIT 1) 
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    u.Reputation BETWEEN 1000 AND 10000
    AND u.CreationDate < (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    AND (u.LastAccessDate IS NULL OR u.LastAccessDate < (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'))
ORDER BY 
    u.Reputation DESC, u.DisplayName
LIMIT 50;
