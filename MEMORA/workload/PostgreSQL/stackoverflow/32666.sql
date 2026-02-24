WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(p.PostCount, 0) AS PostCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            OwnerUserId AS UserId, 
            COUNT(*) AS PostCount 
        FROM 
            Posts 
        GROUP BY 
            OwnerUserId
    ) p ON u.Id = p.UserId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            UserId
    ) c ON u.Id = c.UserId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            UserId
    ) v ON u.Id = v.UserId
),
CombinedActivity AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        CreationDate,
        PostCount,
        CommentCount,
        VoteCount,
        ROW_NUMBER() OVER (PARTITION BY Reputation ORDER BY PostCount DESC) AS Rank
    FROM 
        UserActivity
)

SELECT 
    ca.DisplayName,
    ca.Reputation,
    ca.PostCount,
    ca.CommentCount,
    ca.VoteCount,
    CASE 
        WHEN ca.PostCount > 100 THEN 'Expert Contributor'
        WHEN ca.PostCount > 50 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorStatus,
    (
        SELECT COUNT(*)
        FROM Badges b
        WHERE b.UserId = ca.UserId AND b.Class = 1
    ) AS GoldBadges,
    (
        SELECT COUNT(*)
        FROM Badges b
        WHERE b.UserId = ca.UserId AND b.Class = 2
    ) AS SilverBadges,
    (
        SELECT COUNT(*)
        FROM Badges b
        WHERE b.UserId = ca.UserId AND b.Class = 3
    ) AS BronzeBadges
FROM 
    CombinedActivity ca
WHERE 
    ca.Rank <= 10
ORDER BY 
    ca.Reputation DESC, 
    ca.PostCount DESC;