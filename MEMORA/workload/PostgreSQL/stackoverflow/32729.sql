WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate) AS OwnerPostNumber
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
RecentUserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(r.PostId) AS RecentPostCount,
        AVG(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - r.CreationDate)) / 3600) AS AvgAgeInHours
    FROM 
        Users u
    LEFT JOIN 
        RecursiveCTE r ON u.Id = r.OwnerUserId
    WHERE 
        u.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
JoinWithVotes AS (
    SELECT 
        r.*,
        v.VoteCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount
    FROM 
        RecentUserPosts r
    LEFT JOIN (
        SELECT 
            p.OwnerUserId,
            COUNT(v.Id) AS VoteCount,
            SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Posts p
        JOIN 
            Votes v ON p.Id = v.PostId
        GROUP BY 
            p.OwnerUserId
    ) v ON r.UserId = v.OwnerUserId
),
UserWithBadges AS (
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
    j.UserId,
    j.DisplayName,
    j.RecentPostCount,
    j.AvgAgeInHours,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    j.VoteCount,
    j.UpVoteCount,
    j.DownVoteCount
FROM 
    JoinWithVotes j
LEFT JOIN 
    UserWithBadges b ON j.UserId = b.UserId
WHERE 
    j.RecentPostCount > 5 
ORDER BY 
    j.RecentPostCount DESC, j.AvgAgeInHours ASC;