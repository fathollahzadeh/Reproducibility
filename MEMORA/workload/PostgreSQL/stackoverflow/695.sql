WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(c.UserId, u.Id) AS CommentUserId,
        COALESCE(c.CreationDate, p.CreationDate) AS RelevantDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY COALESCE(c.CreationDate, p.CreationDate) DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
UserPostInteraction AS (
    SELECT 
        a.UserId,
        a.DisplayName,
        COUNT(DISTINCT rp.PostId) AS PostsInteracted,
        SUM(CASE WHEN rp.rn = 1 THEN 1 ELSE 0 END) AS LatestCommentsCount,
        AVG(a.TotalViews) AS AverageViews,
        RANK() OVER (ORDER BY COUNT(DISTINCT rp.PostId) DESC) AS UserRank
    FROM 
        ActiveUsers a
    JOIN 
        RankedPosts rp ON a.UserId = rp.CommentUserId
    GROUP BY 
        a.UserId, a.DisplayName
)

SELECT 
    u.DisplayName,
    u.VoteCount,
    u.TotalViews,
    u.BadgeCount,
    upi.PostsInteracted,
    upi.LatestCommentsCount,
    upi.AverageViews,
    CASE 
        WHEN upi.UserRank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributionLevel
FROM 
    ActiveUsers u
JOIN 
    UserPostInteraction upi ON u.UserId = upi.UserId
WHERE 
    u.VoteCount > 20
ORDER BY 
    u.VoteCount DESC, upi.PostsInteracted DESC;