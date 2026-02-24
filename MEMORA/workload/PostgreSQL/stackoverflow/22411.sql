
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        MAX(c.CreationDate) AS LastCommentDate,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.OwnerUserId
),
AggregatedPostStats AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.LastActivityDate,
        pd.OwnerUserId,
        pd.TotalComments,
        pd.UpVotes,
        pd.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY pd.OwnerUserId ORDER BY pd.LastActivityDate DESC) AS rn,
        CASE 
            WHEN pd.UpVotes > pd.DownVotes THEN 'Positive'
            WHEN pd.UpVotes < pd.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        PostDetails pd
),
RankedUserStats AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.TotalBadges,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        COUNT(DISTINCT ap.PostId) AS PostsContributed,
        SUM(CASE WHEN ap.Sentiment = 'Positive' THEN 1 ELSE 0 END) AS PositiveSentimentPosts,
        SUM(CASE WHEN ap.Sentiment = 'Negative' THEN 1 ELSE 0 END) AS NegativeSentimentPosts
    FROM 
        UserBadges ub
    LEFT JOIN 
        AggregatedPostStats ap ON ub.UserId = ap.OwnerUserId
    GROUP BY 
        ub.UserId, ub.DisplayName, ub.TotalBadges, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalBadges,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    COALESCE(ps.PostsContributed, 0) AS PostsContributed,
    COALESCE(ps.PositiveSentimentPosts, 0) AS PositiveSentiment,
    COALESCE(ps.NegativeSentimentPosts, 0) AS NegativeSentiment,
    CASE
        WHEN COALESCE(ps.PostsContributed, 0) = 0 THEN 'No Contributions'
        WHEN u.TotalBadges > 3 THEN 'Highly Active'
        ELSE 'Moderately Active'
    END AS ActivityLevel
FROM 
    RankedUserStats u
LEFT JOIN 
    RankedUserStats ps ON u.UserId = ps.UserId
WHERE 
    u.TotalBadges > 0
ORDER BY 
    u.TotalBadges DESC, u.DisplayName ASC;
