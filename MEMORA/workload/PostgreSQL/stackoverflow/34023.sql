
WITH RecursivePostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS ActivityRank,
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
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        MAX(b.Date) AS LatestBadgeDate
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
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name IN ('UpMod', 'AcceptedByOriginator') THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    b.BadgeNames,
    pa.Title,
    pa.CreationDate,
    COALESCE(v.VoteCount, 0) AS TotalVotes,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    pa.ViewCount,
    pa.Score
FROM 
    Users u
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    RecursivePostActivity pa ON u.Id = pa.OwnerUserId
LEFT JOIN 
    PostVoteCounts v ON pa.PostId = v.PostId
WHERE 
    (COALESCE(b.BadgeCount, 0) > 0 OR pa.ActivityRank <= 5)  
ORDER BY 
    u.Reputation DESC, pa.Score DESC
LIMIT 100;
