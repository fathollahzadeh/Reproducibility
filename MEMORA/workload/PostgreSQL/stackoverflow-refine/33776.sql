WITH UserBadges AS (
    SELECT 
        b.UserId, 
        b.Class,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId, b.Class
),
UserPostStats AS (
    SELECT 
        p.OwnerUserId AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserVoteStats AS (
    SELECT 
        v.UserId, 
        COUNT(v.Id) AS VoteCount, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(vs.VoteCount, 0) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
    LEFT JOIN 
        UserPostStats ps ON u.Id = ps.UserId
    LEFT JOIN 
        UserVoteStats vs ON u.Id = vs.UserId
    WHERE 
        u.Reputation > 1000
),
RankedUsers AS (
    SELECT 
        UserId, 
        Reputation, 
        BadgeCount, 
        TotalPosts, 
        VoteCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, TotalPosts DESC) AS Rank
    FROM 
        TopUsers
)
SELECT 
    ru.UserId,
    u.DisplayName,
    ru.Reputation,
    ru.BadgeCount,
    ru.TotalPosts,
    ru.VoteCount,
    CASE 
        WHEN ru.BadgeCount > 5 THEN 'Gold Badge Holder'
        WHEN ru.BadgeCount BETWEEN 3 AND 5 THEN 'Silver Badge Holder'
        ELSE 'Bronze Badge Holder'
    END AS BadgeLevel,
    (SELECT COALESCE(SUM(v.BountyAmount), 0) 
     FROM Votes v 
     WHERE v.UserId = ru.UserId AND v.BountyAmount IS NOT NULL) AS TotalBountyPoints
FROM 
    RankedUsers ru
JOIN 
    Users u ON ru.UserId = u.Id
WHERE 
    ru.Rank <= 10
ORDER BY 
    ru.Reputation DESC, ru.TotalPosts DESC;
