
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId, p.Title
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.TotalBadges,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        COUNT(pd.PostId) AS TotalPosts,
        SUM(CASE WHEN pd.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN pd.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(pd.TotalComments) AS TotalComments,
        SUM(pd.UpVotes) AS TotalUpVotes,
        SUM(pd.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostDetails pd ON u.Id = pd.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, ub.TotalBadges, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalBadges,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    Questions,
    Answers,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes
FROM 
    UserPostStats
ORDER BY 
    Reputation DESC, TotalBadges DESC, TotalPosts DESC
LIMIT 10;
