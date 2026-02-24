
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS TotalPosts,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS TotalComments,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalCloseVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
RankedPosts AS (
    SELECT 
        pa.*,
        RANK() OVER (ORDER BY pa.Score DESC, pa.ViewCount DESC) AS PostRank
    FROM 
        PostActivity pa
),
BizarreLogic AS (
    SELECT 
        ups.UserId,
        SUM(CASE WHEN ups.TotalUpvotes > ups.TotalDownvotes THEN 1 ELSE 0 END) AS PositiveContributions,
        SUM(CASE WHEN ups.TotalDownvotes > ups.TotalUpvotes THEN 1 ELSE 0 END) AS NegativeContributions,
        COUNT(DISTINCT rp.PostId) AS ContributingPosts,
        STRING_AGG(rp.Title, '; ') AS PostTitles
    FROM 
        UserStats ups
    LEFT JOIN 
        RankedPosts rp ON ups.UserId = rp.PostId
    WHERE 
        ups.Reputation > 100 AND 
        (ups.GoldBadges + ups.SilverBadges + ups.BronzeBadges) >= 1
    GROUP BY 
        ups.UserId
)
SELECT 
    bl.UserId,
    u.DisplayName,
    bl.PositiveContributions,
    bl.NegativeContributions,
    bl.ContributingPosts,
    bl.PostTitles,
    CASE 
        WHEN bl.PositiveContributions > bl.NegativeContributions THEN 'Overall Positive Contributor' 
        WHEN bl.NegativeContributions > bl.PositiveContributions THEN 'Overall Negative Contributor' 
        ELSE 'Neutral Contributor' 
    END AS ContributionType
FROM 
    BizarreLogic bl
JOIN 
    Users u ON bl.UserId = u.Id
WHERE 
    bl.ContributingPosts > 0
ORDER BY 
    bl.PositiveContributions DESC, 
    bl.NegativeContributions ASC;
