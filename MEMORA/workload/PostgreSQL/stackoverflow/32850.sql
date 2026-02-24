WITH RECURSIVE UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS BadgeRank
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        (ps.UpVotes - ps.DownVotes) AS Score,
        RANK() OVER (ORDER BY (ps.UpVotes - ps.DownVotes + ps.TotalBounty) DESC) AS PostRank
    FROM 
        PostStatistics ps
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN rp.OwnerUserId = u.Id THEN 1 ELSE 0 END), 0) AS TotalPosts,
        COALESCE(SUM(rp.UpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(rp.DownVotes), 0) AS TotalDownVotes,
        MAX(ub.BadgeRank) AS HighestBadgeRank
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    ups.TotalPosts,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    ups.HighestBadgeRank,
    (CASE 
        WHEN ups.HighestBadgeRank IS NULL THEN 'No Badges'
        WHEN ups.HighestBadgeRank = 1 THEN 'Gold'
        WHEN ups.HighestBadgeRank = 2 THEN 'Silver'
        ELSE 'Bronze'
    END) AS HighestBadgeRankName
FROM 
    Users u
LEFT JOIN 
    UserPostStats ups ON u.Id = ups.UserId
WHERE 
    (ups.TotalPosts > 10 OR ups.TotalUpVotes > 100)
ORDER BY 
    ups.TotalPosts DESC, ups.TotalUpVotes DESC;
