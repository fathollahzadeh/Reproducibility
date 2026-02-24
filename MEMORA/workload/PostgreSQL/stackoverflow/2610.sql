
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        COALESCE(np.TotalPosts, 0) AS TotalPosts,
        COALESCE(np.TotalViews, 0) AS TotalViews
    FROM 
        UserStats us
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(*) AS TotalPosts,
            SUM(ViewCount) AS TotalViews
        FROM 
            Posts
        WHERE 
            PostTypeId = 1
        GROUP BY 
            OwnerUserId
    ) np ON us.UserId = np.OwnerUserId
    WHERE 
        us.Reputation > 1000
),
FinalStats AS (
    SELECT 
        tu.DisplayName,
        tu.TotalPosts,
        tu.TotalViews,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.UpVoteCount) AS TotalUpVotes,
        COUNT(DISTINCT rp.PostId) AS DistinctPostCount
    FROM 
        TopUsers tu
    LEFT JOIN 
        RankedPosts rp ON tu.UserId = rp.OwnerUserId
    GROUP BY 
        tu.DisplayName, tu.TotalPosts, tu.TotalViews
)
SELECT 
    f.DisplayName,
    f.TotalPosts,
    f.TotalViews,
    f.TotalComments,
    f.TotalUpVotes,
    f.DistinctPostCount
FROM 
    FinalStats f
ORDER BY 
    f.TotalUpVotes DESC, f.TotalComments DESC
LIMIT 10;
