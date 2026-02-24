
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate >= '2020-01-01' 
        AND u.Views > 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END), 0) AS PositiveScoreCount,
        COALESCE(SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END), 0) AS NegativeScoreCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS LatestPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
        AND p.ViewCount >= 50
    GROUP BY 
        p.Id, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        SUM(pm.CommentCount) AS TotalComments,
        SUM(pm.PositiveScoreCount) AS TotalPositiveScores,
        SUM(pm.NegativeScoreCount) AS TotalNegativeScores
    FROM 
        UserStats us
    LEFT JOIN 
        PostMetrics pm ON us.UserId = pm.OwnerUserId
    GROUP BY 
        us.UserId, us.DisplayName, us.Reputation, us.GoldBadges, us.SilverBadges, us.BronzeBadges
),
FinalOutput AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.Reputation,
        tu.GoldBadges,
        tu.SilverBadges,
        tu.BronzeBadges,
        tu.TotalComments,
        tu.TotalPositiveScores,
        tu.TotalNegativeScores,
        CASE WHEN tu.BronzeBadges > 5 THEN 'Bronze Overachiever'
             WHEN tu.TotalComments > 50 AND tu.GoldBadges > 0 THEN 'Top Contributor'
             ELSE 'Regular User' END AS UserType,
        ROW_NUMBER() OVER (ORDER BY tu.Reputation DESC) AS UserRank
    FROM 
        TopUsers tu
)
SELECT 
    f.UserId,
    f.DisplayName,
    f.Reputation,
    f.GoldBadges,
    f.SilverBadges,
    f.BronzeBadges,
    f.TotalComments,
    f.TotalPositiveScores,
    f.TotalNegativeScores,
    f.UserType,
    f.UserRank
FROM 
    FinalOutput f
WHERE 
    f.UserType <> 'Regular User'
ORDER BY 
    f.TotalPositiveScores DESC, f.UserRank ASC;
