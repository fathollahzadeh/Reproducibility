
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        COUNT(c.Id) AS CommentTotal
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.PostTypeId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount,
        AVG(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - u.LastAccessDate)) / 3600) AS AvgHoursSinceLastAccess
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation >= 1000
    GROUP BY 
        u.Id, u.DisplayName
),
UserPostSummary AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        COUNT(rp.Id) AS PostCount,
        MAX(rp.RecentPostRank) AS HighestRecentPostRank
    FROM 
        UserActivity ua
    LEFT JOIN 
        RankedPosts rp ON ua.UserId = rp.OwnerUserId
    GROUP BY 
        ua.UserId, ua.DisplayName
),
HighEngagementPosts AS (
    SELECT 
        p.Id,
        p.Title, 
        p.OwnerUserId, 
        p.PostTypeId,
        ut.DisplayName AS OwnerName,
        COUNT(co.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoteCount,
        CASE 
            WHEN COUNT(DISTINCT v.UserId) > 50 AND COUNT(co.Id) > 25 THEN 'High Engagement'
            ELSE 'Standard Engagement'
        END AS EngagementType
    FROM 
        Posts p
    JOIN 
        Users ut ON p.OwnerUserId = ut.Id
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.PostTypeId, ut.DisplayName
)

SELECT 
    ups.DisplayName AS UserDisplayName,
    ups.PostCount,
    ups.HighestRecentPostRank,
    he.PostTypeId,
    he.Title,
    he.OwnerName,
    he.CommentCount,
    he.UniqueVoteCount,
    he.EngagementType 
FROM 
    UserPostSummary ups
JOIN 
    HighEngagementPosts he ON ups.UserId = he.OwnerUserId
WHERE 
    ups.PostCount > 10 
    AND ups.HighestRecentPostRank = 1
ORDER BY 
    ups.PostCount DESC, 
    he.UniqueVoteCount DESC
LIMIT 50;
