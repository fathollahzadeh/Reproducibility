
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - p.CreationDate)) ) AS AvgPostAgeInSeconds
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
VoteStatistics AS (
    SELECT
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
BadgesSummary AS (
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
PostEngagement AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedLinksCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    COALESCE(ua.TotalPosts, 0) AS TotalPosts,
    COALESCE(ua.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(ua.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(ua.TotalViews, 0) AS TotalViews,
    COALESCE(va.TotalVotes, 0) AS TotalVotes,
    COALESCE(va.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(va.TotalDownVotes, 0) AS TotalDownVotes,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(pe.CommentCount, 0) AS CommentCount,
    COALESCE(pe.RelatedLinksCount, 0) AS RelatedLinksCount,
    CASE 
        WHEN COALESCE(ua.TotalPosts, 0) = 0 THEN 'No posts yet!'
        WHEN COALESCE(va.TotalVotes, 0) > COALESCE(ua.TotalPosts, 0) THEN 'Votes exceed posts'
        ELSE 'Engaged User'
    END AS EngagementStatus,
    CASE 
        WHEN (COALESCE(ua.AvgPostAgeInSeconds, 0) >= 31536000 AND COALESCE(ua.TotalPosts, 0) < 10) THEN 'Inactive'
        WHEN (COALESCE(ua.TotalViews, 0) = 0 AND COALESCE(ua.TotalPosts, 0) > 5) THEN 'Silent Contributor'
        ELSE 'Active User'
    END AS ActivityStatus
FROM 
    UserActivity ua
LEFT JOIN 
    VoteStatistics va ON ua.UserId = va.UserId
LEFT JOIN 
    BadgesSummary bs ON ua.UserId = bs.UserId
LEFT JOIN 
    PostEngagement pe ON ua.UserId = pe.OwnerUserId
ORDER BY 
    TotalVotes DESC, TotalPosts DESC, ActivityStatus;
