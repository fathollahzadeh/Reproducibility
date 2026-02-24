
WITH RECURSIVE UserVotes AS (
    SELECT 
        v.UserId, 
        p.OwnerUserId, 
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    GROUP BY 
        v.UserId, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS HasAcceptedAnswer,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId
),
UserPostMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(v.VoteCount, 0) AS TotalVotes,
        COALESCE(b.GoldBadges, 0) AS GoldBadges,
        COALESCE(b.SilverBadges, 0) AS SilverBadges,
        COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
        p.PostId,
        p.CommentCount,
        p.HasAcceptedAnswer,
        p.TotalUpVotes,
        p.UserRank
    FROM 
        Users u
    LEFT JOIN 
        UserVotes v ON u.Id = v.UserId
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
    LEFT JOIN 
        PostStats p ON u.Id = p.OwnerUserId
)
SELECT 
    um.UserId,
    um.DisplayName,
    COALESCE(SUM(um.TotalVotes), 0) AS TotalVoteCount,
    COALESCE(SUM(um.GoldBadges), 0) AS TotalGoldBadges,
    COALESCE(SUM(um.SilverBadges), 0) AS TotalSilverBadges,
    COALESCE(SUM(um.BronzeBadges), 0) AS TotalBronzeBadges,
    COALESCE(SUM(um.CommentCount), 0) AS TotalComments,
    COUNT(DISTINCT CASE WHEN um.HasAcceptedAnswer = 1 THEN um.PostId END) AS AcceptedAnswers,
    AVG(um.TotalUpVotes) AS AvgUpVotes
FROM 
    UserPostMetrics um
GROUP BY 
    um.UserId, um.DisplayName
ORDER BY 
    TotalVoteCount DESC, TotalGoldBadges DESC;
