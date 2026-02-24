
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT r.PostId) AS TotalQuestions,
        SUM(r.Score) AS TotalScore,
        SUM(r.ViewCount) AS TotalViews,
        SUM(r.UpVoteCount - r.DownVoteCount) AS NetVotes,
        MAX(r.CreationDate) AS LastPostDate,
        EXTRACT(YEAR FROM AGE(MAX(r.CreationDate))) AS YearsActive
    FROM 
        Users u
    JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
BadgesEarned AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN b.Id END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN b.Id END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN b.Id END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id,
    u.DisplayName,
    us.TotalQuestions,
    us.TotalScore,
    us.TotalViews,
    us.NetVotes,
    COALESCE(be.GoldBadges, 0) AS GoldBadges,
    COALESCE(be.SilverBadges, 0) AS SilverBadges,
    COALESCE(be.BronzeBadges, 0) AS BronzeBadges,
    CASE 
        WHEN us.YearsActive IS NULL THEN 'New User'
        WHEN us.YearsActive < 1 THEN 'Less than a Year'
        ELSE 'Active for over ' || us.YearsActive || ' years'
    END AS UserActivityStatus
FROM 
    Users u
LEFT JOIN 
    UserStatistics us ON u.Id = us.UserId
LEFT JOIN 
    BadgesEarned be ON u.Id = be.UserId
WHERE 
    us.TotalQuestions >= 5
    AND us.NetVotes > 0
ORDER BY 
    us.TotalScore DESC
LIMIT 20
OFFSET 0;
