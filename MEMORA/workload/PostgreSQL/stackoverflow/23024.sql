
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
),
BadgesCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(us.UpVotes, 0) AS UpVotes,
    COALESCE(us.DownVotes, 0) AS DownVotes,
    COALESCE(us.TotalVotes, 0) AS TotalVotes,
    COALESCE(us.AverageBounty, 0) AS AverageBounty,
    COALESCE(bc.BadgeCount, 0) AS TotalBadges,
    COALESCE(bc.BadgeNames, 'No badges') AS Badges,
    rp.PostId,
    rp.Title,
    rp.LastActivityDate,
    CASE 
        WHEN COALESCE(bc.BadgeCount, 0) = 0 THEN 'No Badges Yet'
        WHEN COALESCE(bc.BadgeCount, 0) BETWEEN 1 AND 5 THEN 'Newbie'
        ELSE 'Experienced'
    END AS UserStatus,
    pht.Name AS LastPostType,
    COALESCE(most_recentPostLink.RelatedPostId, 0) AS MostRecentPostLink
FROM 
    Users u
LEFT JOIN 
    UserVoteStats us ON u.Id = us.UserId
LEFT JOIN 
    BadgesCount bc ON u.Id = bc.UserId
LEFT JOIN 
    RecentPostActivity rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    PostTypes pht ON (SELECT postTypeId FROM Posts WHERE Id = rp.PostId) = pht.Id
LEFT JOIN 
    PostLinks most_recentPostLink ON most_recentPostLink.PostId = rp.PostId
WHERE 
    u.Reputation > 10
ORDER BY 
    UpVotes DESC, DownVotes ASC, u.Reputation DESC
LIMIT 100;
