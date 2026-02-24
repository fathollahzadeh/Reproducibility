
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        GoldBadges, 
        SilverBadges, 
        BronzeBadges, 
        UpVotes, 
        DownVotes, 
        TotalScore,
        DENSE_RANK() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    tu.UpVotes,
    tu.DownVotes,
    tu.TotalScore,
    r.Name AS RecentPostType
FROM 
    TopUsers tu
JOIN 
    (SELECT 
        p.OwnerUserId,
        pt.Name,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS RecentPost
     FROM 
        Posts p
     JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
     WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month')) recent_posts ON tu.UserId = recent_posts.OwnerUserId AND recent_posts.RecentPost = 1
JOIN 
    PostTypes r ON recent_posts.Name = r.Name
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.TotalScore DESC;
