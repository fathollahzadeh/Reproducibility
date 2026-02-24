
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.ViewCount > 100 THEN p.Id END) AS HighViewPosts
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
),

RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY p.Id, p.OwnerUserId, p.Title, p.CreationDate
),

EnhancedUserActivity AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.TotalBounty,
        ua.TotalPosts,
        ua.HighViewPosts,
        COALESCE(rp.Title, 'No Recent Posts') AS RecentPostTitle,
        CASE 
            WHEN rp.rn IS NOT NULL THEN 'Yes'
            ELSE 'No'
        END AS HasRecentPost
    FROM UserActivity ua
    LEFT JOIN RecentPosts rp ON ua.UserId = rp.OwnerUserId
)

SELECT 
    eua.UserId,
    eua.DisplayName,
    eua.Reputation,
    eua.TotalBounty,
    eua.TotalPosts,
    eua.HighViewPosts,
    eua.RecentPostTitle,
    eua.HasRecentPost,
    CASE 
        WHEN eua.Reputation < 100 THEN 'Newbie'
        WHEN eua.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserLevel,
    (
        SELECT STRING_AGG(DISTINCT pt.Name, ', ')
        FROM PostTypes pt
        JOIN Posts p ON pt.Id = p.PostTypeId
        WHERE p.OwnerUserId = eua.UserId
    ) AS PostTypesContributedTo,
    (
        SELECT COUNT(*)
        FROM Badges b
        WHERE b.UserId = eua.UserId 
        AND b.Class = 1
    ) AS GoldBadges
FROM EnhancedUserActivity eua
WHERE eua.TotalPosts > 0
ORDER BY eua.Reputation DESC, eua.TotalBounty DESC;
