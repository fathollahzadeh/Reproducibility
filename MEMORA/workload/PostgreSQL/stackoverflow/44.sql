WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
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
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        -- CreationDate must be in GROUP BY to be used here
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        -- Standardized Interval for Calcite 1.41
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1' YEAR
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.AcceptedAnswerId, p.CreationDate
),
AggregateData AS (
    SELECT
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.BadgeCount,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        SUM(pd.CommentCount) AS TotalComments,
        SUM(pd.Upvotes) AS TotalUpvotes,
        SUM(pd.Downvotes) AS TotalDownvotes,
        COUNT(pd.PostId) AS TotalPosts,
        AVG(pd.PostRank) AS AveragePostRank
    FROM 
        UserReputation ur
    JOIN 
        PostDetails pd ON ur.UserId = pd.OwnerUserId
    GROUP BY 
        ur.UserId, ur.DisplayName, ur.Reputation, ur.BadgeCount, ur.GoldBadges, ur.SilverBadges, ur.BronzeBadges
)
SELECT 
    a.DisplayName,
    a.Reputation,
    a.BadgeCount,
    a.GoldBadges,
    a.SilverBadges,
    a.BronzeBadges,
    COALESCE(a.TotalPosts, 0) AS TotalPosts,
    COALESCE(a.TotalComments, 0) AS TotalComments,
    COALESCE(a.TotalUpvotes, 0) AS TotalUpvotes,
    COALESCE(a.TotalDownvotes, 0) AS TotalDownvotes,
    CASE 
        WHEN a.AveragePostRank IS NULL THEN 'No Posts'
        WHEN a.AveragePostRank < 3 THEN 'Average Performer'
        ELSE 'Top Performer'
    END AS PerformanceCategory
FROM 
    AggregateData a
ORDER BY 
    a.Reputation DESC, a.TotalPosts DESC;