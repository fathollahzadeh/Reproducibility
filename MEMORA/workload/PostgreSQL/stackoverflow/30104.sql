WITH RecursiveUserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(rb.GoldBadges, 0) AS GoldBadges,
        COALESCE(rb.SilverBadges, 0) AS SilverBadges,
        COALESCE(rb.BronzeBadges, 0) AS BronzeBadges,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' AND p.PostTypeId = 1 THEN 1 ELSE 0 END) AS RecentQuestions,
        r.PostCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges rb ON u.Id = rb.UserId
    LEFT JOIN (
        SELECT 
            PostOwnerId,
            COUNT(*) AS VoteCount
        FROM 
            (SELECT 
                v.UserId AS PostOwnerId,
                v.Id 
            FROM 
                Votes v 
            JOIN 
                Posts p ON v.PostId = p.Id 
            WHERE 
                v.VoteTypeId IN (2, 3) 
            ) AS votes_by_user
        GROUP BY 
            PostOwnerId
    ) v ON u.Id = v.PostOwnerId
    LEFT JOIN 
        RecursiveUserPosts r ON u.Id = r.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, rb.GoldBadges, rb.SilverBadges, rb.BronzeBadges, r.PostCount
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    ua.TotalVotes,
    ua.TotalViews,
    ua.RecentQuestions,
    ua.PostCount,
    CASE 
        WHEN ua.TotalVotes > 100 THEN 'Active'
        WHEN ua.RecentQuestions > 10 THEN 'Engaged'
        ELSE 'Casual User'
    END AS UserEngagementLevel
FROM 
    UserActivity ua
WHERE 
    ua.PostCount > 0
ORDER BY 
    ua.TotalVotes DESC, 
    ua.TotalViews DESC
LIMIT 100;